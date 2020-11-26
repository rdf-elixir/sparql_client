defmodule SPARQL.Client.Update do
  @moduledoc false

  @behaviour SPARQL.Client.Operation

  @default_request_method :direct

  def default_request_method do
    Application.get_env(:sparql_client, :query_request_method, @default_request_method)
  end

  @impl true
  def query_parameter_key, do: "update"

  @impl true
  def init(request, opts) do
    with {:ok, protocol_version, request_method} <-
           opts |> Keyword.get(:request_method, default_request_method()) |> request_method() do
      {:ok,
       %{
         request
         | sparql_protocol_version: protocol_version,
           http_method: request_method,
           http_content_type_header: content_type(protocol_version, request_method)
       }}
    end
  end

  defp request_method(:direct), do: {:ok, "1.1", :post}
  defp request_method(:url_encoded), do: {:ok, "1.0", :post}

  defp content_type("1.1", :post), do: "application/sparql-update"
  defp content_type("1.0", :post), do: "application/x-www-form-urlencoded"
  defp content_type(_, _), do: nil

  @impl true
  def http_headers(request, _opts) do
    {:ok, %{"Content-Type" => request.http_content_type_header}}
  end

  @impl true
  def evaluate_response(request, _), do: {:ok, %{request | result: :ok}}
end
