defmodule SPARQL.Client.Request do
  @doc false

  defstruct [
    :sparql_operation,
    :sparql_operation_type,
    :sparql_operation_form,
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

  def build(operation, endpoint, opts \\ [])

  def build(operation, endpoint, opts) do
    %__MODULE__{
      sparql_endpoint: endpoint,
      sparql_operation: operation,
      sparql_protocol_version: Keyword.get(opts, :protocol_version),
      sparql_graph_params: graph_params(opts)
    }
    |> init_operation(operation, opts)
  end

  defp init_operation(request, %SPARQL.Query{} = query, opts) do
    SPARQL.Client.Query.init(request, query, opts)
  end

  defp graph_params(opts) do
    opts
    |> Enum.reduce([], fn
      {:default_graph, graph_uris}, acc when is_list(graph_uris) ->
        Enum.reduce(graph_uris, acc, fn graph_uri, acc ->
          [{"default-graph-uri", graph_uri} | acc]
        end)

      {:default_graph, graph_uri}, acc ->
        [{"default-graph-uri", graph_uri} | acc]

      {:named_graph, graph_uris}, acc when is_list(graph_uris) ->
        Enum.reduce(graph_uris, acc, fn graph_uri, acc ->
          [{"named-graph-uri", graph_uri} | acc]
        end)

      {:named_graph, graph_uri}, acc ->
        [{"named-graph-uri", graph_uri} | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

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
