defmodule SPARQL.Client do
  @moduledoc """
  A [SPARQL protocol](https://www.w3.org/TR/sparql11-protocol/) HTTP client.
  """

  use Tesla

  import ContentType


  @default_request_method :post
  @default_protocol_version "1.0"

  @default_select_accept_header [
      SPARQL.Query.Result.JSON.content_type,
      SPARQL.Query.Result.XML.content_type,
      "#{SPARQL.Query.Result.TSV.content_type};p=0.8",
      "#{SPARQL.Query.Result.CSV.content_type};p=0.2",
      "*/*;p=0.1"
    ] |> Enum.join(", ")

  @default_ask_accept_header [
      SPARQL.Query.Result.JSON.content_type,
      SPARQL.Query.Result.XML.content_type,
      "*/*;p=0.1"
    ] |> Enum.join(", ")



  @doc """
  The query operation is used to send a SPARQL query to a service and receive the results of the query.
  """
  def query(endpoint, query, options \\ %{})

  def query(query, endpoint, options) when is_list(options),
    do: query(query, endpoint, Map.new(options))

  def query(%SPARQL.Query{} = query, endpoint, options) do
    with {:ok, client}   <- client(query, endpoint, options),
         {:ok ,response} <- http_request(client, endpoint, query, options)
    do
      evaluate_response(query, response, options)
    end
  end

  def query(query_string, endpoint, options) do
    with query = SPARQL.Query.new(query_string) do
      query(query, endpoint, options)
    end
  end


  ############################################################################
  # Configuration

  defp request_method(%{request_method: request_method}), do: request_method
  defp request_method(_),                                 do: @default_request_method

  defp protocol_version(%{protocol_version: protocol_version}), do: protocol_version
  defp protocol_version(_),                                     do: @default_protocol_version

  defp result_format(%{result_format: result_format}), do: SPARQL.result_format(result_format)
  defp result_format(_),                               do: nil

  def default_accept_header(:select), do: @default_select_accept_header
  def default_accept_header(:ask),    do: @default_ask_accept_header
  def default_accept_header(%SPARQL.Query{form: form}), do: default_accept_header(form)



# TODO:  defp native_results?(options), do: false


  ############################################################################
  # HTTP Request building

  defp client(query, _endpoint, options) do
    with {:ok, headers} <- request_headers(query, options) do
      {:ok,
        Tesla.build_client [
          {Tesla.Middleware.Tuples,  rescue_errors: :all},
          {Tesla.Middleware.Headers, headers}
        ]
      }
    end
  end

  defp request_headers(query, options) do
    {:ok,
        options
        |> Map.get(:headers, %{})
        |> add_content_type(request_method(options), protocol_version(options))
        |> add_accept_header(query, result_format(options))
    }
  end

  defp add_content_type(headers, :post, "1.1"),
    do: Map.put(headers, "Content-Type", "application/sparql-query")
  defp add_content_type(headers, :post, "1.0"),
    do: Map.put(headers, "Content-Type", "application/x-www-form-urlencoded")
  defp add_content_type(headers, _, _), do: headers

  defp add_accept_header(headers, query, :all),
    do: Map.put(headers, "Accept", default_accept_header(query))
  defp add_accept_header(headers, query, nil),
    do: Map.put_new(headers, "Accept", default_accept_header(query))
  defp add_accept_header(headers, _query, result_format),
    do: Map.put(headers, "Accept", result_format.content_type)



  ############################################################################
  # HTTP Request execution

  defp http_request(client, endpoint, query, options) do
    do_http_request(client, request_method(options), protocol_version(options), endpoint, query)
  end

  defp do_http_request(client, :get, "1.1", endpoint, query) do
    client
    |> get(endpoint <> "?" <> URI.encode_query(%{query: query.query_string}))
  end

  defp do_http_request(client, :post, "1.1", endpoint, query) do
    client
    |> post(endpoint, query.query_string)
  end

  defp do_http_request(client, :post, "1.0", endpoint, query) do
    client
    |> post(endpoint, URI.encode_query(%{query: query.query_string}))
  end

  defp do_http_request(_, request_method, protocol_version, _, _),
    do: {:error, "unknown request method: #{inspect request_method} with SPARQL protocol version #{protocol_version}"}


  ############################################################################
  # HTTP Response evaluation

  defp evaluate_response(query, response, options) do
    with result_format when is_atom(result_format) <-
          response_result_format(response, options) do
      if query.form in result_format.supported_query_forms do
        result_format.decode(response.body)
      else
        {:error, "unsupported result format for #{query.form} query: #{inspect result_format.content_type}"}
      end
    end
  end

  defp response_result_format(%Tesla.Env{headers: %{"content-type" => content_type}}, options) do
    ( content_type
      |> parse_content_type()
      |> SPARQL.result_format_by_content_type()
    ) || result_format(options)
      || {:error, "unsupported result format: #{inspect content_type}"}
  end

  defp parse_content_type(content_type) do
    with {:ok, type, subtype, _params} <- content_type(content_type) do
      type <> "/" <> subtype
    end
  end

end
