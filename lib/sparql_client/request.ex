defmodule SPARQL.Client.Request do
  @moduledoc """
  A struct representing a HTTP request of a SPARQL protocol operation.

  For now, you won't have to deal with this struct that much.
  You'll encounter it only as a member of a `SPARQL.Client.HTTPError` or when writing a custom
  config function for the HTTP headers (see documentation of the configuration options for `SPARQL.Client`).
  """

  defstruct [
    :sparql_operation_type,
    :sparql_operation_form,
    :sparql_operation_payload,
    :sparql_endpoint,
    :sparql_protocol_version,
    :sparql_graph_params,
    :http_method,
    :http_headers,
    :http_content_type_header,
    :http_accept_header,
    :http_body,
    :http_status,
    :http_response_content_type,
    :http_response_body,
    :result
  ]

  @type protocol_version :: String.t()
  @type http_method :: :get | :post

  @type t :: %__MODULE__{
          sparql_operation_type: module,
          sparql_operation_form: atom,
          sparql_operation_payload: String.t(),
          sparql_endpoint: String.t(),
          sparql_protocol_version: protocol_version,
          sparql_graph_params: list,
          http_method: http_method,
          http_headers: map,
          http_content_type_header: String.t(),
          http_accept_header: String.t(),
          http_body: String.t() | nil,
          http_status: pos_integer,
          http_response_content_type: String.t(),
          http_response_body: String.t(),
          result: SPARQL.Query.Result.t() | RDF.Data.t()
        }

  alias RDF.IRI

  @doc false
  def build(type, form, payload, endpoint, opts \\ []) do
    %__MODULE__{
      sparql_endpoint: endpoint,
      sparql_operation_type: type,
      sparql_operation_form: form,
      sparql_operation_payload: payload,
      sparql_graph_params: graph_params(type, opts)
    }
    |> init_operation(opts)
    |> add_http_headers(opts)
  end

  defp init_operation(request, opts) do
    request.sparql_operation_type.init(request, opts)
  end

  @doc false
  def operation_http_headers(request, opts \\ []) do
    request.sparql_operation_type.http_headers(request, opts)
  end

  @doc false
  def query_parameter_key(request) do
    request.sparql_operation_type.query_parameter_key()
  end

  defp add_http_headers({:ok, request}, opts) do
    with {:ok, headers} <- operation_http_headers(request, opts) do
      {:ok,
       %{
         request
         | http_headers: Map.merge(headers, default_http_headers(request, headers, opts))
       }}
    end
  end

  defp add_http_headers(error, _opts), do: error

  defp default_http_headers do
    Application.get_env(:sparql_client, :http_headers)
  end

  defp default_http_headers(request, headers, opts) do
    case Keyword.get(opts, :headers, default_http_headers()) do
      fun when is_function(fun) -> fun.(request, headers)
      nil -> %{}
      default_headers -> default_headers
    end
  end

  defp graph_params(SPARQL.Client.Query, opts) do
    Enum.flat_map(opts, fn
      {:default_graph, graph_uris} when is_list(graph_uris) ->
        Enum.map(graph_uris, &{"default-graph-uri", to_graph_name(&1)})

      {:default_graph, graph_uri} ->
        [{"default-graph-uri", to_graph_name(graph_uri)}]

      {:named_graph, graph_uris} when is_list(graph_uris) ->
        Enum.map(graph_uris, &{"named-graph-uri", to_graph_name(&1)})

      {:named_graph, graph_uri} ->
        [{"named-graph-uri", to_graph_name(graph_uri)}]

      _ ->
        []
    end)
  end

  defp graph_params(SPARQL.Client.Update, opts) do
    Enum.flat_map(opts, fn
      {:using_graph, graph_uris} when is_list(graph_uris) ->
        Enum.map(graph_uris, &{"using-graph-uri", to_graph_name(&1)})

      {:using_graph, graph_uri} ->
        [{"using-graph-uri", to_graph_name(graph_uri)}]

      {:using_named_graph, graph_uris} when is_list(graph_uris) ->
        Enum.map(graph_uris, &{"using-named-graph-uri", to_graph_name(&1)})

      {:using_named_graph, graph_uri} ->
        [{"using-named-graph-uri", to_graph_name(graph_uri)}]

      _ ->
        []
    end)
  end

  defp to_graph_name(iri), do: iri |> RDF.iri() |> IRI.to_string()

  @doc false
  def call(%__MODULE__{} = request, opts) do
    case SPARQL.Client.Tesla.call(request, opts) do
      {:ok, %__MODULE__{http_status: status} = request} when status in 200..299 ->
        request.sparql_operation_type.evaluate_response(request, opts)

      {:ok, request} ->
        {:error, %SPARQL.Client.HTTPError{request: request, status: request.http_status}}

      error ->
        error
    end
  end
end
