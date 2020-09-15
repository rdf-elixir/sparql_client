defmodule SPARQL.Client.Tesla do
  @doc false

  use Tesla, docs: false

  alias SPARQL.Client.Request

  def call(request, opts) do
    with {:ok, client} <- client(request, opts),
         {:ok, response} <- http_request(client, request, opts) do
      {:ok, evaluate_tesla_response(request, response, opts)}
    end
  end

  defp client(request, opts) do
    {:ok,
     Tesla.client([
       {Tesla.Middleware.Headers, Map.to_list(request.http_headers)},
       {Tesla.Middleware.FollowRedirects, max_redirects: Keyword.get(opts, :max_redirects, 5)}
     ])}
  end

  defp http_request(client, request, opts) do
    with {:ok, operation} <- Request.operation_string(request, opts) do
      do_http_request(
        client,
        request.http_method,
        request.sparql_protocol_version,
        request.sparql_endpoint,
        operation,
        Request.query_parameter_key(request),
        request.sparql_graph_params,
        opts
      )
    end
  end

  defp do_http_request(client, :get, "1.1", endpoint, query, query_param_key, graph_params, opts) do
    get(
      client,
      endpoint <> "?" <> URI.encode_query([{query_param_key, query} | graph_params]),
      tesla_request_opts(opts)
    )
  end

  defp do_http_request(client, :post, "1.1", endpoint, query, _, graph_params, opts) do
    url =
      case graph_params do
        [] -> endpoint
        graph_params -> endpoint <> "?" <> URI.encode_query(graph_params)
      end

    post(client, url, query, tesla_request_opts(opts))
  end

  defp do_http_request(client, :post, "1.0", endpoint, query, query_param_key, graph_params, opts) do
    post(
      client,
      endpoint,
      URI.encode_query([{query_param_key, query} | graph_params]),
      tesla_request_opts(opts)
    )
  end

  defp tesla_request_opts(opts) do
    if Keyword.has_key?(opts, :request_opts) do
      [opts: Keyword.get(opts, :request_opts)]
    else
      []
    end
  end

  defp evaluate_tesla_response(request, response, _opts) do
    %{
      request
      | http_status: response.status,
        http_response_content_type: Tesla.get_header(response, "content-type"),
        http_response_body: response.body
    }
  end
end
