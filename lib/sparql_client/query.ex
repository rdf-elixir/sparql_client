defmodule SPARQL.Client.Query do
  @doc false

  alias SPARQL.Client.ResultFormat

  @default_select_accept_header [
                                  SPARQL.Query.Result.JSON.media_type(),
                                  SPARQL.Query.Result.XML.media_type(),
                                  "#{SPARQL.Query.Result.TSV.media_type()};p=0.8",
                                  "#{SPARQL.Query.Result.CSV.media_type()};p=0.2",
                                  "*/*;p=0.1"
                                ]
                                |> Enum.join(", ")

  @default_ask_accept_header [
                               SPARQL.Query.Result.JSON.media_type(),
                               SPARQL.Query.Result.XML.media_type(),
                               "*/*;p=0.1"
                             ]
                             |> Enum.join(", ")

  @default_rdf_accept_header [
                               RDF.Turtle.media_type(),
                               RDF.NTriples.media_type(),
                               RDF.NQuads.media_type(),
                               JSON.LD.media_type(),
                               "*/*;p=0.1"
                             ]
                             |> Enum.join(", ")

  def init(request, query, opts) do
    with {:ok, request_method} <-
           opts |> Keyword.get(:request_method) |> request_method(request),
         {:ok, accept_header} <-
           accept_header(query.form, opts) do
      {:ok,
       %{
         request
         | sparql_operation_type: __MODULE__,
           sparql_operation_form: query.form,
           http_method: request_method,
           http_content_type_header:
             content_type(request.sparql_protocol_version, request_method),
           http_accept_header: accept_header
       }
       |> add_headers(opts)}
    end
  end

  defp request_method(nil, %{sparql_protocol_version: "1.0"}), do: {:ok, :post}
  defp request_method(nil, %{sparql_protocol_version: "1.1"}), do: {:ok, :get}
  defp request_method(:post, _), do: {:ok, :post}
  defp request_method(:get, %{sparql_protocol_version: "1.1"}), do: {:ok, :get}

  defp request_method(request_method, request) do
    {:error,
     "request_method #{inspect(request_method)} is not supported with protocol_version #{
       inspect(request.sparql_protocol_version)
     }"}
  end

  defp content_type("1.1", :post), do: "application/sparql-query"
  defp content_type("1.0", :post), do: "application/x-www-form-urlencoded"
  defp content_type(_, _), do: nil

  defp accept_header(query_form, opts) do
    cond do
      accept_header = Keyword.get(opts, :accept_header) ->
        {:ok, accept_header}

      result_format = Keyword.get(opts, :result_format) ->
        result_media_type(query_form, result_format)

      true ->
        {:ok, default_accept_header(query_form)}
    end
  end

  defp result_media_type(query_form, result_format) do
    if format = ResultFormat.by_name(result_format, query_form) do
      {:ok, format.media_type}
    else
      {:error, "#{result_format} is not a valid result format for #{query_form} queries"}
    end
  end

  def default_accept_header(:select), do: @default_select_accept_header
  def default_accept_header(:ask), do: @default_ask_accept_header
  def default_accept_header(:describe), do: @default_rdf_accept_header
  def default_accept_header(:construct), do: @default_rdf_accept_header

  defp add_headers(request, opts) do
    %{
      request
      | http_headers:
          %{
            "Content-Type" => request.http_content_type_header,
            "Accept" => request.http_accept_header
          }
          |> Map.merge(Keyword.get(opts, :headers, %{}))
    }
  end

  def evaluate_response(request, opts) do
    with {:ok, result_format} <-
           response_result_format(request, opts),
         {:ok, result} <-
           result_format.read_string(request.http_response_body) do
      {:ok, %{request | result: result}}
    end
  end

  defp response_result_format(request, opts) do
    with {:ok, media_type} <- parse_content_type(request.http_response_content_type) do
      query_form = request.sparql_operation_form

      cond do
        format = ResultFormat.by_media_type(media_type, query_form) ->
          {:ok, format}

        format = opts |> Keyword.get(:result_format) |> ResultFormat.by_name(query_form) ->
          {:ok, format}

        true ->
          {:error,
           "SPARQL service responded with #{media_type} content which can't be interpreted. Try specifying one of the supported result formats with the :result_format option."}
      end
    end
  end

  defp parse_content_type(content_type) do
    with {:ok, type, subtype, _params} <- ContentType.content_type(content_type) do
      {:ok, type <> "/" <> subtype}
    end
  end
end
