defmodule SPARQL.Client do
  @moduledoc """
  A SPARQL protocol client.

  The [SPARQL Protocol](https://www.w3.org/TR/sparql11-protocol/) consists of
  two HTTP operations:

  - a query operation for performing SPARQL 1.0 and 1.1 Query Language queries
  - an update operation for performing SPARQL Update Language requests, which is
    not implemented yet
  """

  use Tesla, docs: false

  import ContentType


  @default_request_method :post
  @default_protocol_version "1.0"

  @default_select_accept_header [
      SPARQL.Query.Result.JSON.media_type,
      SPARQL.Query.Result.XML.media_type,
      "#{SPARQL.Query.Result.TSV.media_type};p=0.8",
      "#{SPARQL.Query.Result.CSV.media_type};p=0.2",
      "*/*;p=0.1"
    ] |> Enum.join(", ")

  @default_ask_accept_header [
      SPARQL.Query.Result.JSON.media_type,
      SPARQL.Query.Result.XML.media_type,
      "*/*;p=0.1"
    ] |> Enum.join(", ")

  @default_rdf_accept_header [
      RDF.Turtle.media_type,
      RDF.NTriples.media_type,
      RDF.NQuads.media_type,
      JSON.LD.media_type,
      "*/*;p=0.1"
    ] |> Enum.join(", ")


  @doc """
  The query operation is used to send a SPARQL query to a service endpoint and receive the results of the query.

  The query can either be given as string or as an already parsed `SPARQL.Query`.

      with %SPARQL.Query{} = query <- SPARQL.Query.new("SELECT * WHERE { ?s ?p ?o }") do
        SPARQL.Client.query(query, "http://dbpedia.org/sparql")
      end

  The type of the result returned depends on the query form:

  - `SELECT` queries will return a `SPARQL.Query.ResultSet` struct with a list of
    `SPARQL.Query.Result` structs in the `results` field.
  - `ASK` queries will return a `SPARQL.Query.ResultSet` struct with the boolean
    result in the `results` field
  - `CONSTRUCT` and `DESCRIBE` queries will return an RDF data structure


  ## Specifying the request method

  The SPARQL 1.1 protocol spec defines [three methods](https://www.w3.org/TR/sparql11-protocol/#query-operation)
  to perform a SPARQL query operation via HTTP, which can be specified via the
  `request_method` and `protocol_version` options:

  1. query via GET: by setting the options as `request_method: :get` and `protocol_version: "1.1"`
  2. query via URL-encoded POST: by setting the options as `request_method: :post` and `protocol_version: "1.0"`
  3. query via POST directly: by setting the options as `request_method: :post` and `protocol_version: "1.1"`

  In order to work with SPARQL 1.0 services out-of-the-box the second method,
  query via URL-encoded POST, is the default.

  To perform previous query via GET, you would have to call it like this:

      SPARQL.Client.query(query, "http://dbpedia.org/sparql",
        request_method: :get, protocol_version: "1.1")


  ## Specifying custom headers

  You can specify custom headers for the HTTP request to the SPARQL service with
  the `headers` option and a map.

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        headers: %{"Authorization" => "Basic XXX=="})


  ## Specifying the response format

  The `SPARQL.Client` can handle all of the specified result formats for SPARQL
  tuple results (JSON, XML, CSV and TSV) and for `CONSTRUCT` and `DESCRIBE` queries
  all RDF serialization formats supported by [RDF.ex](https://github.com/marcelotto/rdf-ex)
  can be handled.

  If no custom `Accept` header is specified, all accepted formats for the resp.
  query form will be set automatically, with

  - JSON being the preferred format for `SELECT` and `ASK` queries
  - Turtle being the preferred format for `CONSTRUCT` and `DESCRIBE` queries

  Although the returned result is mostly independent from the actually returned
  response format from the service, you might want to set it manually with the
  `result_format` and the name of the format

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        result_format: :xml)

  These are the names of the supported formats:

  - tuple result formats: `:json, :xml, :csv, :tsv`
  - RDF result formats: `:turtle, :ntriples, :nquads, :jsonld`

  When a `result_format` is specified the `Accept` header is set to the corresponding
  media type. You might however still want to overwrite the `Accept` header, for
  example when a SPARQL service uses a non-standard media type for a format.
  Note that, when providing a custom non-standard `Accept` header the `result_format`
  option is mandatory.


  ## Specifying an RDF Dataset

  The RDF dataset to be queried can be specified [as described in the spec](https://www.w3.org/TR/sparql11-protocol/#dataset)
  via the the `default_graph` and `named_graph` options and either a single dataset
  names or lists of datasets.

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        default_graph: "http://www.example/sparql/",
        named_graph: [
          "http://www.other.example/sparql/",
          "http://www.another.example/sparql/"
        ])


  ## Other options

  - `max_redirects`: the number of redirects to follow before the operation fails (default: `5`)
  - `request_opts`: will be passed as the `opts` option value to the `Tesla.request/2` function,
    this allows for example to set the timeout value for the Hackney adapter like this:

  ```elixir
  SPARQL.Client.query(query, "http://example.com/sparql",
    request_opts: [adapter: [recv_timeout: 30_000]])
  ```

  For a general introduction you may refer to the guides on the [homepage](https://rdf-elixir.dev).
  """
  def query(query, endpoint, options \\ %{})

  def query(query, endpoint, options) when is_list(options),
    do: query(query, endpoint, Map.new(options))

  def query(%SPARQL.Query{} = query, endpoint, options) do
    with {:ok, client}   <- client(query, endpoint, options),
         {:ok, response} <- http_request(client, endpoint, query, options)
    do
      evaluate_response(query, response, options)
    end
  end

  def query(query_string, endpoint, options) do
    with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
      query(query, endpoint, options)
    end
  end


  ############################################################################
  # Configuration

  defp request_method(%{request_method: request_method}), do: request_method
  defp request_method(_),                                 do: @default_request_method

  defp protocol_version(%{protocol_version: protocol_version}), do: protocol_version
  defp protocol_version(_),                                     do: @default_protocol_version

  defp result_format(query_form, %{result_format: result_format})
    when query_form in ~w[select ask]a,
    do: SPARQL.result_format(result_format)
  defp result_format(query_form, %{result_format: result_format})
    when query_form in ~w[construct describe]a,
    do: RDF.Serialization.format(result_format)
  defp result_format(_, _), do: nil

  @doc false
  def default_accept_header(query_form)
  def default_accept_header(:select),    do: @default_select_accept_header
  def default_accept_header(:ask),       do: @default_ask_accept_header
  def default_accept_header(:describe),  do: @default_rdf_accept_header
  def default_accept_header(:construct), do: @default_rdf_accept_header
  def default_accept_header(%SPARQL.Query{form: form}), do: default_accept_header(form)


  ############################################################################
  # HTTP Request building

  defp client(query, _endpoint, options) do
    with {:ok, headers} <- request_headers(query, options) do
      {:ok,
        Tesla.client [
          {Tesla.Middleware.Headers, Map.to_list(headers)},
          {Tesla.Middleware.FollowRedirects,
            max_redirects: Map.get(options, :max_redirects, 5)}
        ]
      }
    end
  end

  defp request_headers(query, options) do
    {:ok,
        options
        |> Map.get(:headers, %{})
        |> add_content_type(request_method(options), protocol_version(options))
        |> add_accept_header(query, result_format(query.form, options))
    }
  end

  defp add_content_type(headers, :post, "1.1"),
    do: Map.put(headers, "Content-Type", "application/sparql-query")
  defp add_content_type(headers, :post, "1.0"),
    do: Map.put(headers, "Content-Type", "application/x-www-form-urlencoded")
  defp add_content_type(headers, _, _), do: headers

  defp add_accept_header(headers, query, nil),
    do: Map.put_new(headers, "Accept", default_accept_header(query))
  defp add_accept_header(headers, _query, result_format),
    do: Map.put_new(headers, "Accept", result_format.media_type)

  defp graph_params(options) do
    options
    |> Enum.reduce([], fn
         {:default_graph, graph_uris}, acc when is_list(graph_uris) ->
           Enum.reduce graph_uris, acc, fn graph_uri, acc ->
             [{"default-graph-uri", graph_uri} | acc]
           end
         {:default_graph, graph_uri}, acc ->
           [{"default-graph-uri", graph_uri} | acc]
         {:named_graph, graph_uris}, acc when is_list(graph_uris) ->
           Enum.reduce graph_uris, acc, fn graph_uri, acc ->
             [{"named-graph-uri", graph_uri} | acc]
           end
         {:named_graph, graph_uri}, acc ->
           [{"named-graph-uri", graph_uri} | acc]
         _, acc ->
           acc
       end)
    |> Enum.reverse()
  end


  ############################################################################
  # HTTP Request execution

  defp http_request(client, endpoint, query, options) do
    do_http_request(client, request_method(options), protocol_version(options), endpoint, query, options)
  end

  defp do_http_request(client, :get, "1.1", endpoint, query, options) do
    client
    |> get(endpoint <> "?" <> URI.encode_query(
            [{"query", query.query_string} | graph_params(options)]), tesla_request_opts(options))
  end

  defp do_http_request(client, :post, "1.1", endpoint, query, options) do
    url =
      case graph_params(options) do
        []           -> endpoint
        graph_params -> endpoint <> "?" <> URI.encode_query(graph_params)
      end

    client
    |> post(url, query.query_string, tesla_request_opts(options))
  end

  defp do_http_request(client, :post, "1.0", endpoint, query, options) do
    client
    |> post(endpoint, URI.encode_query(
              [{"query", query.query_string} | graph_params(options)]), tesla_request_opts(options))
  end

  defp do_http_request(_, request_method, protocol_version, _, _, _),
    do: {:error, "unknown request method: #{inspect request_method} with SPARQL protocol version #{protocol_version}"}

  defp tesla_request_opts(options) do
    if Map.has_key?(options, :request_opts) do
      [opts: Map.get(options, :request_opts)]
    else
      []
    end
  end


  ############################################################################
  # HTTP Response evaluation

  defp evaluate_response(query, %Tesla.Env{status: status} = response, options)
    when status in 200..299
  do
    with result_format when is_atom(result_format) <-
          response_result_format(query.form, response, options) do
      if query.form in ~w[construct describe]a or
         query.form in result_format.supported_query_forms do
        result_format.read_string(response.body)
      else
        {:error, "unsupported result format for #{query.form} query: #{inspect result_format.media_type}"}
      end
    end
  end

  defp evaluate_response(_, response, _), do: {:error, response}


  defp response_result_format(query_form, env, options) do
    content_type = Tesla.get_header(env, "content-type")
    ( content_type
      |> parse_content_type()
      |> result_format_by_media_type(query_form)
    ) || result_format(query_form, options)
      || {:error, "unsupported result format for #{query_form} query: #{inspect content_type}"}
  end

  defp result_format_by_media_type(media_type, query_form)
    when query_form in ~w[select ask]a,
    do: SPARQL.result_format_by_media_type(media_type)

  defp result_format_by_media_type(media_type, query_form)
    when query_form in ~w[construct describe]a,
    do: RDF.Serialization.format_by_media_type(media_type)


  defp parse_content_type(content_type) do
    with {:ok, type, subtype, _params} <- content_type(content_type) do
      type <> "/" <> subtype
    end
  end

end
