defmodule SPARQL.Client.Tesla do
  @moduledoc false

  use Tesla, docs: false

  alias SPARQL.Client.Request

  @default_max_redirects 5

  def default_max_redirects do
    Application.get_env(:sparql_client, :max_redirects, @default_max_redirects)
  end

  def default_request_opts do
    Application.get_env(:sparql_client, :tesla_request_opts)
  end

  def call(request, opts) do
    with {:ok, client} <- client(request, opts),
         {:ok, response} <- http_request(client, request, opts) do
      {:ok, evaluate_tesla_response(request, response, opts)}
    end
  end

  defp client(request, opts) do
    middleware = [
      {Tesla.Middleware.Headers, Map.to_list(request.http_headers)},
      {Tesla.Middleware.FollowRedirects,
       max_redirects: Keyword.get(opts, :max_redirects, default_max_redirects())}
    ]

    middleware =
      case Keyword.get(opts, :logger, false) do
        false -> middleware
        true -> middleware ++ [Tesla.Middleware.Logger]
        log_opts when is_list(log_opts) -> middleware ++ [{Tesla.Middleware.Logger, log_opts}]
      end

    {:ok, Tesla.client(middleware)}
  end

  defp http_request(client, request, opts) do
    do_http_request(
      client,
      request.http_method,
      request.sparql_protocol_version,
      request.sparql_endpoint,
      request.sparql_operation_payload,
      Request.query_parameter_key(request),
      request.sparql_graph_params,
      opts
    )
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
    if request_opts = Keyword.get(opts, :request_opts, default_request_opts()) do
      [opts: request_opts]
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
