defmodule SPARQL.Client do
  @moduledoc """
  A SPARQL protocol client.

  The [SPARQL Protocol](https://www.w3.org/TR/sparql11-protocol/) consists of
  two HTTP operations:

  - a query operation for performing SPARQL 1.0 and 1.1 Query Language queries
  - an update operation for performing SPARQL Update Language requests, which is
    not implemented yet
  """

  alias SPARQL.Client.Request

  @query_options_schema [
    request_method: [
      type: {:one_of, [:get, :post]},
      subsection: "Specifying the request method"
    ],
    protocol_version: [
      type: {:one_of, ["1.0", "1.1"]},
      default: "1.0",
      subsection: "Specifying the request method"
    ],
    accept_header: [
      type: :string
    ],
    headers: [
      type: {:custom, __MODULE__, :validate_headers, []},
      subsection: "Specifying custom headers"
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
    ],
    request_opts: [
      type: :keyword_list,
      subsection: "Specifying Tesla adapter specific options"
    ],
    max_redirects: [
      type: :pos_integer,
      default: 5,
      doc: "The number of redirects to follow before the HTTP request fails."
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
    with {:ok, options} <- NimbleOptions.validate(options, @query_options_schema),
         {:ok, request} <- Request.build(query, endpoint, options),
         {:ok, request} <- Request.call(request, options) do
      {:ok, request.result}
    else
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
      error -> error
    end
  end

  def query(query_string, endpoint, options) do
    with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
      query(query, endpoint, options)
    end
  end

  @doc false
  def validate_headers(map) when is_map(map), do: {:ok, map}

  def validate_headers(other),
    do: {:error, "expected :headers to be a map, got: #{inspect(other)}"}
end
