defmodule SPARQL.Client.Query do
  @moduledoc false

  @behaviour SPARQL.Client.Operation

  alias SPARQL.Client.Query.ResultFormat

  @forms ~w[select construct ask describe]a

  def forms, do: @forms

  @default_select_accept_header [
                                  SPARQL.Query.Result.JSON.media_type(),
                                  SPARQL.Query.Result.XML.media_type(),
                                  "#{SPARQL.Query.Result.TSV.media_type()};q=0.8",
                                  "#{SPARQL.Query.Result.CSV.media_type()};q=0.2",
                                  "*/*;q=0.1"
                                ]
                                |> Enum.join(", ")

  @default_ask_accept_header [
                               SPARQL.Query.Result.JSON.media_type(),
                               SPARQL.Query.Result.XML.media_type(),
                               "*/*;q=0.1"
                             ]
                             |> Enum.join(", ")

  @default_rdf_accept_header [
                               RDF.Turtle.media_type(),
                               RDF.NTriples.media_type(),
                               RDF.NQuads.media_type(),
                               JSON.LD.media_type(),
                               "*/*;q=0.1"
                             ]
                             |> Enum.join(", ")

  @default_request_method :post

  def default_request_method do
    Application.get_env(:sparql_client, :query_request_method, @default_request_method)
  end

  def default_protocol_version do
    Application.get_env(:sparql_client, :protocol_version)
  end

  def default_result_format(query_form) do
    if formats = Application.get_env(:sparql_client, :query_result_format) do
      formats[query_form]
    end
  end

  @impl true
  def query_parameter_key, do: "query"

  @impl true
  def init(request, opts) do
    with {:ok, protocol_version, request_method} <-
           request_method(
             Keyword.get(opts, :protocol_version, default_protocol_version()),
             Keyword.get(opts, :request_method, default_request_method())
           ),
         {:ok, accept_header} <-
           accept_header(request.sparql_operation_form, opts) do
      {:ok,
       %{
         request
         | sparql_protocol_version: protocol_version,
           http_method: request_method,
           http_content_type_header: content_type(protocol_version, request_method),
           http_accept_header: accept_header
       }}
    end
  end

  defp request_method("1.0", nil), do: {:ok, "1.0", :post}
  defp request_method("1.1", nil), do: {:ok, "1.1", :get}
  defp request_method(nil, :get), do: {:ok, "1.1", :get}
  defp request_method(nil, :post), do: {:ok, "1.0", :post}
  defp request_method("1.1", :get), do: {:ok, "1.1", :get}
  defp request_method("1.0", :post), do: {:ok, "1.0", :post}
  defp request_method("1.1", :post), do: {:ok, "1.1", :post}

  defp request_method(sparql_protocol_version, request_method) do
    {:error,
     "request_method #{inspect(request_method)} is not supported with a query and protocol_version #{
       sparql_protocol_version
     }"}
  end

  defp content_type("1.1", :post), do: "application/sparql-query"
  defp content_type("1.0", :post), do: "application/x-www-form-urlencoded"
  defp content_type(_, _), do: nil

  defp accept_header(query_form, opts) do
    cond do
      accept_header = Keyword.get(opts, :accept_header) ->
        {:ok, accept_header}

      result_format = Keyword.get(opts, :result_format, default_result_format(query_form)) ->
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

  @impl true
  def http_headers(request, _opts) do
    {:ok,
     %{
       "Content-Type" => request.http_content_type_header,
       "Accept" => request.http_accept_header
     }}
  end

  @impl true
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

        format =
            opts
            |> Keyword.get(:result_format, default_result_format(request.sparql_operation_form))
            |> ResultFormat.by_name(query_form) ->
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

  @impl true
  def operation_string(request, _), do: {:ok, request.sparql_operation_payload}
end
