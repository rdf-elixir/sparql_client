defmodule SPARQL.Client do
  @moduledoc """
  A SPARQL protocol client.

  The [SPARQL Protocol](https://www.w3.org/TR/sparql11-protocol/) defines how the operations
  specified in the SPARQL query and update specs can be requested by a client from a
  SPARQL service via HTTP.

  This modules provides dedicated functions for the various forms of SPARQL query and update
  operations and generic `query/3` and `update/3` for the query and update operations.

  For a general introduction you may refer to the guides on the [homepage](https://rdf-elixir.dev).


  ## Raw-mode

  The query functions can be called with a `SPARQL.Query` struct or a SPARQL query as a raw string.
  By default, a SPARQL query string will be parsed into a `SPARQL.Query` struct for validation
  purposes before the string is send via an HTTP request to the SPARQL protocol service endpoint.
  This parsing step can be omitted by setting `:raw_mode` option to `true` on the dedicated
  functions for the various SPARQL operation forms.

      "SELECT * { ?s ?p ?o .}"
      |> SPARQL.Client.select("http://example.com/sparql", raw_mode: true)

  On the generic `SPARQL.Client.query/3` this raw-mode is not supported, since the parsing is
  needed there to determine the query form which determines which result to expect.

  For SPARQL update operations the picture is a little different. The SPARQL.ex package doesn't
  provide parsing of SPARQL updates (yet), but except for `INSERT` and `DELETE` updates this isn't
  actually needed, since all elements of the updates can be provided directly to the respective
  functions for the update forms, which will generate valid SPARQL updates.

      RDF.Graph.new({EX.S, EX.p, EX.O})
      |> SPARQL.Client.insert_data("http://example.com/sparql")

  You can still provide hand-written update strings to these functions, but due to the lack of
  SPARQL update parsing the raw-mode is mandatory then. For the `INSERT` and `DELETE` update
  forms this the only way to request them for now.

      \"""
      PREFIX dc:  <http://purl.org/dc/elements/1.1/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      INSERT
      { GRAPH <http://example/bookStore2> { ?book ?p ?v } }
      WHERE
      { GRAPH  <http://example/bookStore>
           { ?book dc:date ?date .
             FILTER ( ?date > "1970-01-01T00:00:00-02:00"^^xsd:dateTime )
             ?book ?p ?v
      } }
      \"""
      |> SPARQL.Client.insert("http://example.com/sparql", raw_mode: true)


  ## Specifying custom headers

  Custom headers for the HTTP request to the SPARQL service can be specified with the `headers`
  option and a map.

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        headers: %{"Authorization" => "Basic XXX=="})


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
  - `logger`: allows to enable and configure the `Tesla.Middleware.Logger` by
    either setting it `true` or providing the `Tesla.Middleware.Logger` options
    (default: `false`)


  ## Application configuration of default values

  Several default values for the options of the operations can be configured via the
  Mix application environment.
  Here's an example configuration showing all available configuration options:

      config :sparql_client,
        protocol_version: "1.1",
        query_request_method: :get,
        update_request_method: :direct,
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
        "Allows disabling of the processing of query strings, passing them through as-is to the SPARQL endpoint.",
      subsection: "Raw-mode"
    ],
    logger: [
      type: {:or, [:boolean, :keyword_list]},
      doc: "Allows to enable and configure the Tesla Logger middleware"
    ]
  ]

  @query_options_schema @general_options_schema ++
                          [
                            protocol_version: [
                              type: {:in, ["1.0", "1.1"]},
                              subsection: "Specifying the request method"
                            ],
                            request_method: [
                              type: {:in, [:get, :post]},
                              subsection: "Specifying the request method"
                            ],
                            accept_header: [
                              type: :string
                            ],
                            result_format: [
                              type:
                                {:in,
                                 (SPARQL.result_formats() ++ RDF.Serialization.formats())
                                 |> Enum.map(fn format -> format.name() end)},
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
  Executes any form of a SPARQL query operation against a service endpoint.

  The query can either be given as string or as an already parsed `SPARQL.Query`.

      "SELECT * WHERE { ?s ?p ?o }"
      |> SPARQL.Client.query(query, "http://dbpedia.org/sparql")

      with %SPARQL.Query{} = query <- SPARQL.Query.new("SELECT * WHERE { ?s ?p ?o }") do
        SPARQL.Client.query(query, "http://dbpedia.org/sparql")
      end

  For the execution of queries in raw-mode see the [module documentation](`SPARQL.Client`)

  The result is in the success case returned in a `:ok` tuple or in error cases in an `:error`
  tuple with an error message or in case of a non-200 response by the SPARQL service with a
  `SPARQL.Client.HTTPError`.

  The type of the result returned depends on the query form:

  - `SELECT` queries will return a `SPARQL.Query.Result` struct
  - `ASK` queries will return a `SPARQL.Query.Result` struct with the boolean
    result in the `results` field
  - `CONSTRUCT` and `DESCRIBE` queries will return an RDF data structure


  ## Specifying the request method

  The SPARQL 1.1 protocol spec defines [three methods](https://www.w3.org/TR/sparql11-protocol/#query-operation)
  to perform a SPARQL query operation via HTTP, which can be specified via the
  `:request_method` and `:protocol_version` options:

  1. query via GET: by setting the options as `request_method: :get` and `protocol_version: "1.1"`
  2. query via URL-encoded POST: by setting the options as `request_method: :post` and `protocol_version: "1.0"`
  3. query via POST directly: by setting the options as `request_method: :post` and `protocol_version: "1.1"`

  In order to work with SPARQL 1.0 services out-of-the-box the second method,
  query via URL-encoded POST, is the default.

  To perform previous query via GET, you would have to call it like this:

      SPARQL.Client.query(query, "http://dbpedia.org/sparql",
        request_method: :get, protocol_version: "1.1")


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
  `:result_format` and the name of the format

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        result_format: :xml)

  These are the names of the supported formats:

  - tuple result formats: `:json, :xml, :csv, :tsv`
  - RDF result formats: `:turtle, :ntriples, :nquads, :jsonld`

  When a `:result_format` is specified the `Accept` header is set to the corresponding
  media type. You might however still want to overwrite the `Accept` header, for
  example when a SPARQL service uses a non-standard media type for a format.
  Note that, when providing a custom non-standard `Accept` header the `result_format`
  option is mandatory.


  ## Specifying an RDF Dataset

  The RDF dataset to be queried can be specified [as described in the spec](https://www.w3.org/TR/sparql11-protocol/#dataset)
  via the `:default_graph` and `:named_graph` options and either a single graph
  name or lists of graphs.

      SPARQL.Client.query(query, "http://some.company.org/private/sparql",
        default_graph: "http://www.example/sparql/",
        named_graph: [
          "http://www.other.example/sparql/",
          "http://www.another.example/sparql/"
        ])

  Similarly, the `:using_graph` and `:using_named_graph` can be used to
  specify the dataset on update operation [as described in the spec](https://www.w3.org/TR/sparql11-protocol/#update-dataset).

      SPARQL.Client.update(update, "http://some.company.org/private/sparql",
        using_graph: "http://www.example/sparql/",
        using_named_graph: [
          "http://www.other.example/sparql/",
          "http://www.another.example/sparql/"
        ])

  """

  def query(query, endpoint, opts \\ [])

  def query(%SPARQL.Query{} = query, endpoint, opts) do
    do_query(query.form, query.query_string, endpoint, opts)
  end

  def query(query_string, endpoint, opts) do
    if Keyword.get(opts, :raw_mode) do
      raise """
      The generic SPARQL.Client.query/3 function can not be used in raw-mode since
      it needs to parse the query to determine the query form.
      Please use one of the dedicated functions like SPARQL.Client.select/3 etc.
      """
    end

    with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
      query(query, endpoint, opts)
    end
  end

  SPARQL.Client.Query.forms()
  |> Enum.each(fn query_form ->
    @doc """
    Executes a SPARQL `#{query_form |> to_string() |> String.upcase()}` query operation against a service endpoint.

    See documentation of the generic `query/3` function and the [module documentation](`SPARQL.Client`) for the available options.
    """
    def unquote(query_form)(query, endpoint, opts \\ [])

    def unquote(query_form)(%SPARQL.Query{form: unquote(query_form)} = query, endpoint, opts) do
      do_query(unquote(query_form), query.query_string, endpoint, opts)
    end

    def unquote(query_form)(%SPARQL.Query{form: form}, _, _) do
      raise "expected a #{unquote(query_form) |> to_string() |> String.upcase()} query, got: #{form |> to_string() |> String.upcase()} query"
    end

    def unquote(query_form)(query_string, endpoint, opts) do
      if raw_mode?(opts) do
        do_query(unquote(query_form), query_string, endpoint, opts)
      else
        with %SPARQL.Query{} = query <- SPARQL.Query.new(query_string) do
          unquote(query_form)(query, endpoint, opts)
        end
      end
    end
  end)

  defp do_query(form, query, endpoint, opts) do
    with {:ok, options} <- NimbleOptions.validate(opts, @query_options_schema),
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
                               type: {:in, [:direct, :url_encoded]},
                               subsection: "Specifying the request method"
                             ],
                             using_graph: [
                               subsection: "Specifying an RDF Dataset"
                             ],
                             using_named_graph: [
                               subsection: "Specifying an RDF Dataset"
                             ],
                             prefixes: [
                               doc:
                                 "The prefixes to be used when generating an update. This has currently only effect on INSERT DATA and DELETE DATA updates."
                             ]
                           ]

  @doc """
  Executes any form of a SPARQL update operation against a service endpoint.

  In case of this generic function, updates can be given only as string and executed in raw-mode
  (see the [module documentation](`SPARQL.Client`) for a description of the raw-mode)

      \"""
      PREFIX dc:  <http://purl.org/dc/elements/1.1/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      INSERT
      { GRAPH <http://example/bookStore2> { ?book ?p ?v } }
      WHERE
      { GRAPH  <http://example/bookStore>
           { ?book dc:date ?date .
             FILTER ( ?date > "1970-01-01T00:00:00-02:00"^^xsd:dateTime )
             ?book ?p ?v
      } }
      \"""
      |> SPARQL.Client.update("http://example.com/sparql", raw_mode: true)


  The result for all updates is either `:ok` or an `:error` tuple in error cases with an error
  message or in case of a non-2XX response by the SPARQL service with a `SPARQL.Client.HTTPError`.

  ## Specifying the request method

  The SPARQL 1.1 protocol spec defines [two methods](https://www.w3.org/TR/sparql11-protocol/#update-operation)
  to perform a SPARQL update operation via HTTP, which can be specified via the
  `request_method` option:

  1. Update via URL-encoded POST: by setting the options `request_method: :url_encoded`
  2. Update via POST directly: by setting the options `request_method: :direct` (default)

  """
  def update(update, endpoint, opts \\ []) do
    unvalidated_update(nil, update, endpoint, opts)
  end

  @doc """
  Executes a SPARQL `INSERT` update operation against a service endpoint.

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def insert(update, endpoint, opts \\ []) do
    unvalidated_update(:insert, update, endpoint, opts)
  end

  @doc """
  Executes a SPARQL `DELETE` update operation against a service endpoint.

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def delete(update, endpoint, opts \\ []) do
    unvalidated_update(:delete, update, endpoint, opts)
  end

  @doc """
  Executes a SPARQL `INSERT DATA` update operation against a service endpoint.

  The `INSERT DATA` update can either be given as string (only in raw-mode; see the
  [module documentation](`SPARQL.Client`) for more information on the raw-mode) or
  by providing the data to be inserted directly via an RDF.ex data structure
  (`RDF.Graph`, `RDF.Description` or `RDF.Dataset`).

      RDF.Graph.new({EX.S, EX.p, EX.O})
      |> SPARQL.Client.insert_data("http://example.com/sparql")

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def insert_data(data_or_update, endpoint, opts \\ []) do
    update_data(:insert_data, data_or_update, endpoint, opts)
  end

  @doc """
  Executes a SPARQL `DELETE DATA` update operation against a service endpoint.

  The `DELETE DATA` update can either be given as string (only in raw-mode; see the
  [module documentation](`SPARQL.Client`) for more information on the raw-mode) or
  by providing the data to be deleted directly via an RDF.ex data structure
  (`RDF.Graph`, `RDF.Description` or `RDF.Dataset`).

      RDF.Graph.new({EX.S, EX.p, EX.O})
      |> SPARQL.Client.delete_data("http://example.com/sparql")

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def delete_data(data_or_update, endpoint, opts \\ []) do
    update_data(:delete_data, data_or_update, endpoint, opts)
  end

  defp update_data(form, %rdf{} = data, endpoint, opts)
       when rdf in [RDF.Graph, RDF.Description, RDF.Dataset] do
    with {:ok, update_string} <- Client.Update.Builder.update_data(form, data, opts) do
      do_update(form, update_string, endpoint, opts)
    end
  end

  defp update_data(form, update, endpoint, opts) when is_binary(update) do
    unvalidated_update(form, update, endpoint, opts)
  end

  @doc """
  Executes a SPARQL `LOAD` update operation against a service endpoint.

  The URL from to be loaded must be specified with the `:from` option. The graph name
  to which the data should be loaded can be given with the `:to` option. Both options
  expect an URI as a value which can be given as a string, `RDF.IRI` or vocabulary namespace term.

      SPARQL.Client.load("http://example.com/sparql", from: "http://example.com/Resource")

      SPARQL.Client.load("http://example.com/sparql", from: EX.Resource, to: EX.Graph)

  The update operation can be run in `SILENT` mode by setting the `:silent` option to `true`.

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def load(endpoint, opts) when is_list(opts) do
    {from, opts} = pop_required_keyword(opts, :from)
    {to, opts} = Keyword.pop(opts, :to)
    {silent, opts} = Keyword.pop(opts, :silent)

    with {:ok, update_string} <- Client.Update.Builder.load(from, to, silent) do
      do_update(:load, update_string, endpoint, opts)
    end
  end

  @doc """
  Executes a SPARQL `LOAD` update operation against a service endpoint.

  This version only allows execution of `LOAD` update given as string in raw-mode (see the
  [module documentation](`SPARQL.Client`) for more information on the raw-mode).

      "LOAD <http://example.com/Resource>"
      |> SPARQL.Client.load("http://example.com/sparql", raw_mode: true)

  See `load/2` for how to execute a `LOAD` update with an automatically build update string.

  See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
  """
  def load(update, endpoint, opts) do
    if Keyword.has_key?(opts, :from) or Keyword.has_key?(opts, :to) or
         Keyword.has_key?(opts, :silent) do
      raise ArgumentError,
            "load/3 does not support the :from, :to and :silent options; use load/2 instead"
    end

    update_data(:load, update, endpoint, opts)
  end

  ~w[create clear drop]a
  |> Enum.each(fn form ->
    form_keyword = form |> to_string() |> String.upcase()

    @doc """
    Executes a SPARQL `#{form_keyword}` update operation against a service endpoint.

    The graph name must be specified with the `:graph` option either as a string, `RDF.IRI`,
    vocabulary namespace term or one of the special values `:default`, `:named`, `:all`.

        SPARQL.Client.#{form}("http://example.com/sparql", graph: "http://example.com/Graph")

        SPARQL.Client.#{form}("http://example.com/sparql", graph: EX.Graph)

    The update operation can be run in `SILENT` mode by setting the `:silent` option to `true`.

    See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
    """
    def unquote(form)(endpoint, opts) when is_list(opts) do
      {graph, opts} = pop_required_keyword(opts, :graph)
      {silent, opts} = Keyword.pop(opts, :silent)

      with {:ok, update_string} <- apply(Client.Update.Builder, unquote(form), [graph, silent]) do
        do_update(unquote(form), update_string, endpoint, opts)
      end
    end

    @doc """
    Executes a SPARQL `#{form_keyword}` update operation against a service endpoint.

    This version only allows execution of `#{form_keyword}` updates given as string in raw-mode (see the
    [module documentation](`SPARQL.Client`) for more information on the raw-mode).

        "#{form_keyword} <http://example.com/Graph>"
        |> SPARQL.Client.#{form}("http://example.com/sparql", raw_mode: true)

    See `#{form}/2` for how to execute a `#{form_keyword}` update with an automatically build update string.

    See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
    """
    def unquote(form)(update, endpoint, opts) do
      if Keyword.has_key?(opts, :graph) or Keyword.has_key?(opts, :silent) do
        raise ArgumentError,
              "#{unquote(form)}/3 does not support the :graph and :silent options; use #{unquote(form)}/2 instead"
      end

      update_data(unquote(form), update, endpoint, opts)
    end
  end)

  ~w[copy move add]a
  |> Enum.each(fn form ->
    form_keyword = form |> to_string() |> String.upcase()

    @doc """
    Executes a SPARQL `#{form_keyword}` update operation against a service endpoint.

    The source graph must be specified with the `:graph` option and the destination graph with the
    `:to` option either as a string, `RDF.IRI`, vocabulary namespace term for the graph name or
    `:default` for the default graph.

        SPARQL.Client.#{form}("http://example.com/sparql",
          from: "http://example.com/Graph1", to: "http://example.com/Graph2")

        SPARQL.Client.#{form}("http://example.com/sparql",
          from: :default, to: EX.Graph)


    The update operation can be run in `SILENT` mode by setting the `:silent` option to `true`.

    See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
    """
    def unquote(form)(endpoint, opts) when is_list(opts) do
      {from, opts} = pop_required_keyword(opts, :from)
      {to, opts} = pop_required_keyword(opts, :to)
      {silent, opts} = Keyword.pop(opts, :silent)

      with {:ok, update_string} <- apply(Client.Update.Builder, unquote(form), [from, to, silent]) do
        do_update(unquote(form), update_string, endpoint, opts)
      end
    end

    @doc """
    Executes a SPARQL `#{form_keyword}` update operation against a service endpoint.

    This version only allows execution of `#{form_keyword}` updates given as string in raw-mode (see the
    [module documentation](`SPARQL.Client`) for more information on the raw-mode).

        "#{form_keyword} GRAPH <http://example.com/Graph1> TO GRAPH <http://example.com/Graph2>"
        |> SPARQL.Client.#{form}("http://example.com/sparql", raw_mode: true)

    See `#{form}/2` for how to execute a `#{form_keyword}` update with an automatically build update string.

    See documentation of the generic `update/3` function and the [module documentation](`SPARQL.Client`) for the available options.
    """
    def unquote(form)(update, endpoint, opts) do
      if Keyword.has_key?(opts, :from) or Keyword.has_key?(opts, :to) or
           Keyword.has_key?(opts, :silent) do
        raise ArgumentError,
              "#{unquote(form)}/3 does not support the :from, :to and :silent options; use #{unquote(form)}/2 instead"
      end

      update_data(unquote(form), update, endpoint, opts)
    end
  end)

  defp unvalidated_update(form, update, endpoint, opts) do
    unless raw_mode?(opts) do
      raise """
      An update options is passed directly as a string. Validation of updates is not implemented yet.
      Please run them in raw-mode, by providing the raw_mode: true option.
      """
    end

    do_update(form, update, endpoint, opts)
  end

  defp do_update(form, update_string, endpoint, opts) do
    with {:ok, options} <- NimbleOptions.validate(opts, @update_options_schema),
         {:ok, request} <- Request.build(Client.Update, form, update_string, endpoint, options),
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

  defp default_raw_mode do
    Application.get_env(:sparql_client, :raw_mode, false)
  end

  defp raw_mode?(opts) do
    Keyword.get(opts, :raw_mode, default_raw_mode())
  end

  defp pop_required_keyword(opts, key) do
    case Keyword.pop(opts, key) do
      {nil, _} -> raise "missing required keyword option #{inspect(key)}"
      result -> result
    end
  end
end
