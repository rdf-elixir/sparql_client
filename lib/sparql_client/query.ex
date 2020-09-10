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
    %{
      request
      | sparql_operation_type: __MODULE__,
        sparql_operation_form: query.form,
        # TODO: It should be validated if the combination makes sense (1.0 with get is invalid)
        http_method: Keyword.get(opts, :request_method, default_request_method(request))
    }
    |> add_content_type_header(opts)
    |> add_accept_header(opts)
    |> add_headers(opts)
  end

  defp default_request_method(%{sparql_protocol_version: "1.0"}), do: :post
  defp default_request_method(%{sparql_protocol_version: "1.1"}), do: :get

  defp add_content_type_header(
         %{sparql_protocol_version: "1.1", http_method: :post} = request,
         _opts
       ),
       do: %{request | http_content_type_header: "application/sparql-query"}

  defp add_content_type_header(
         %{sparql_protocol_version: "1.0", http_method: :post} = request,
         _opts
       ),
       do: %{request | http_content_type_header: "application/x-www-form-urlencoded"}

  defp add_content_type_header(request, _), do: request

  defp add_accept_header(request, opts) do
    %{
      request
      | http_accept_header:
          Keyword.get(opts, :accept_header) ||
            result_media_type(Keyword.get(opts, :result_format), request.sparql_operation_form) ||
            default_accept_header(request.sparql_operation_form)
    }
  end

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

  defp result_media_type(nil, _), do: nil

  defp result_media_type(result_format, query_form) do
    if format = ResultFormat.by_name(result_format, query_form) do
      format.media_type
    else
      raise "#{result_format} is not a valid result format for #{query_form} queries"
    end
  end

  def default_accept_header(:select), do: @default_select_accept_header
  def default_accept_header(:ask), do: @default_ask_accept_header
  def default_accept_header(:describe), do: @default_rdf_accept_header
  def default_accept_header(:construct), do: @default_rdf_accept_header

  def evaluate_response(request, opts) do
    with {:ok, result_format} <-
           response_result_format(request, opts),
         {:ok, result} <-
           result_format.read_string(request.http_response_body) do
      {:ok, %{request | result: result}}
    end
  end

  defp response_result_format(request, opts) do
    with {:ok, media_type} <-
           parse_content_type(request.http_response_content_type),
         query_form = request.sparql_operation_form,
         format when not is_nil(format) <-
           ResultFormat.by_media_type(media_type, query_form) ||
             ResultFormat.by_name(Keyword.get(opts, :result_format), query_form) do
      {:ok, format}
    else
      nil ->
        {:error, "unsupported result format: #{request.http_response_content_type}"}
    end
  end

  defp parse_content_type(content_type) do
    with {:ok, type, subtype, _params} <- ContentType.content_type(content_type) do
      {:ok, type <> "/" <> subtype}
    end
  end
end
