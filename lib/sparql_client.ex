defmodule SPARQL.Client do
  @moduledoc """
  A SPARQL protocol client.

  The [SPARQL Protocol](https://www.w3.org/TR/sparql11-protocol/) consists of
  HTTP operations:

  - a query operation for performing SPARQL 1.0 and 1.1 Query Language queries
  - an update operation for performing SPARQL Update Language requests, which is
    not fully implemented yet

  # Configuration

  Several default values for options of the operations can be configured via the
  Mix application environment.

  Here's an example configuration showing all available configuration options:

      config :sparql_client,
        protocol_version: "1.1",
        query_request_method: :get,
        update_request_method: :directly,
        query_result_format: %{
          select: :json,
          ask: :json,
          construct: :turtle,
          describe: :turtle
        },
        http_headers: %{"Authorization" => "Basic YWxhZGRpbjpvcGVuc2VzYW1l"},
        tesla_request_opts: [adapter: [recv_timeout: 30_000]],
        max_redirects: 3,
        raw_mode: true

  The `http_headers` can also be set to a function receiving the `SPARQL.Client.Request`
  struct and the computed default headers:

      defmodule SomeModule do
        def http_header_config(request, _headers) do
          if request.sparql_operation_type == SPARQL.Client.Update do
            %{"Authorization" => "Basic YWxhZGRpbjpvcGVuc2VzYW1l"}
          else
            %{}
          end
      end

      config :sparql_client,
        http_headers: &SomeModule.http_header_config/2,

  """

  alias __MODULE__
  alias SPARQL.Client.Request

  def default_raw_mode do
    Application.get_env(:sparql_client, :raw_mode, false)
  end

  @general_options_schema [
    headers: [
      type: {:custom, __MODULE__, :validate_headers, []},
      subsection: "Specifying custom headers"
    ],
    request_opts: [
      type: :keyword_list,
      subsection: "Specifying Tesla adapter specific options"
    ],
    max_redirects: [
      type: :pos_integer,
      doc: "The number of redirects to follow before the HTTP request fails."
    ],
    raw_mode: [
      type: :boolean,
      doc:
        "Allows disabling of the processing of query strings, passing them through as-is to the SPARQL endpoint."
    ]
  ]

  @query_options_schema @general_options_schema ++
                          [
                            protocol_version: [
                              type: {:one_of, ["1.0", "1.1"]},
                              subsection: "Specifying the request method"
                            ],
                            request_method: [
                              type: {:one_of, [:get, :post]},
                              subsection: "Specifying the request method"
                            ],
                            accept_header: [
                              type: :string
                            ],
                            result_format: [
                              type:
                                {:one_of,
                                 (SPARQL.result_formats() ++ RDF.Serialization.formats())
                                 |> Enum.map(fn format -> format.name end)},
                              subsection: "Specifying the response format"
                            ],
                            default_graph: [
                              subsection: "Specifying an RDF Dataset"
                            ],
                            named_graph: [
                              subsection: "Specifying an RDF Dataset"
                            ]
                          ]

  @doc """
  The query operation is used to send a SPARQL query to a service endpoint and receive the results of the query.

  The query can either be given as string or as an already parsed `SPARQL.Query`.

      with %SPARQL.Query{} = query <- SPARQL.Query.new("SELECT * WHERE { ?s ?p ?o }") do
        SPARQL.Client.query(query, "http://dbpedia.org/sparql")
      end

  The result is in the success case returned in a `:ok` tuple or in error cases in an `:error`
  tuple with an error message or in case of a non-200 response by the SPARQL service with a
  `SPARQL.Client.HTTPError`.

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
  all RDF serialization formats supported by [RDF.ex](https://github.com/rdf-elixir/rdf-ex)
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
  via the the `default_graph` and `named_graph` options and either a single graph
  name or lists of graphs.

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        default_graph: "http://www.example/sparql/",
        named_graph: [
          "http://www.other.example/sparql/",
          "http://www.another.example/sparql/"
        ])


  ## Specifying Tesla adapter specific options

  The keyword list provided under the  `request_opts` options, will be passed as the `opts` option
  value to the `Tesla.request/2` function.
  This allows for example to set the timeout value for the Hackney adapter like this:

  ```elixir
  SPARQL.Client.query(query, "http://example.com/sparql",
    request_opts: [adapter: [recv_timeout: 30_000]])
  ```


  ## Other options

  - `max_redirects`: the number of redirects to follow before the operation fails (default: `5`)

  For a general introduction you may refer to the guides on the [homepage](https://rdf-elixir.dev).
  """

  def query(query, endpoint, options \\ [])

  def query(%SPARQL.Query{} = query, endpoint, options) do
    do_query(query.form, query.query_string, endpoint, options)
  end

  def query(query_string, endpoint, options) do
    if Keyword.get(options, :raw_mode) do
      raise """
      The generic SPARQL.Client.query/3 function can not be used in raw-mode since
      it needs to parse the query to determine the query form.
      Please use one of the dedicated functions like SPARQL.Client.select/3 etc.
      """
    end

    with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
      query(query, endpoint, options)
    end
  end

  SPARQL.Client.Query.forms()
  |> Enum.each(fn query_form ->
    def unquote(query_form)(query, endpoint, options \\ [])

    def unquote(query_form)(%SPARQL.Query{form: unquote(query_form)} = query, endpoint, options) do
      do_query(unquote(query_form), query.query_string, endpoint, options)
    end

    def unquote(query_form)(%SPARQL.Query{form: form}, _, _) do
      raise "expected a #{unquote(query_form) |> to_string() |> String.upcase()} query, got: #{
              form |> to_string() |> String.upcase()
            } query"
    end

    def unquote(query_form)(query_string, endpoint, options) do
      if Keyword.get(options, :raw_mode, default_raw_mode()) do
        do_query(unquote(query_form), query_string, endpoint, options)
      else
        with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
          unquote(query_form)(query, endpoint, options)
        end
      end
    end
  end)

  defp do_query(form, query, endpoint, options) do
    with {:ok, options} <- NimbleOptions.validate(options, @query_options_schema),
         {:ok, request} <- Request.build(Client.Query, form, query, endpoint, options),
         {:ok, request} <- Request.call(request, options) do
      {:ok, request.result}
    else
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
      error -> error
    end
  end

  @update_options_schema @general_options_schema ++
                           [
                             request_method: [
                               type: {:one_of, [:direct, :url_encoded]},
                               subsection: "Specifying the request method"
                             ]
                           ]

  def insert_data(data, endpoint, options \\ []) do
    update(:insert_data, data, endpoint, options)
  end

  def delete_data(data, endpoint, options \\ []) do
    update(:delete_data, data, endpoint, options)
  end

  defp update(form, data, endpoint, options) do
    with {:ok, options} <- NimbleOptions.validate(options, @update_options_schema),
         {:ok, request} <- Request.build(Client.Update, form, data, endpoint, options),
         {:ok, _request} <- Request.call(request, options) do
      :ok
    else
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
      error -> error
    end
  end

  @doc false
  def validate_headers(map) when is_map(map), do: {:ok, map}

  def validate_headers(other),
    do: {:error, "expected :headers to be a map, got: #{inspect(other)}"}
end
