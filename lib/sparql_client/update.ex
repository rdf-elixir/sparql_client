defmodule SPARQL.Client.Update do
  @moduledoc false

  @behaviour SPARQL.Client.Operation

  alias RDF.Turtle
  import SPARQL.Client.Utils

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
  def operation_string(request, opts) do
    to_sparql(request.sparql_operation_form, request.sparql_operation_payload, opts)
  end

  def to_sparql(update_form, data, opts \\ [])

  def to_sparql(update_form, data, opts) do
    with {:ok, prologue} <-
           Turtle.write_string(
             data,
             Keyword.merge(opts, only: :directives, directive_style: :sparql)
           ),
         {:ok, triples} <-
           to_sparql_triples(update_form, data, Keyword.get(opts, :merge_graphs, false), opts) do
      {:ok,
       """
       #{prologue}
       #{sparql_update_data_keyword(update_form)} DATA {
       #{triples}
       }
       """}
    end
  end

  defp to_sparql_triples(update_form, %RDF.Dataset{} = dataset, false, opts) do
    dataset
    |> RDF.Dataset.graphs()
    |> map_join_while_ok("\n", fn
      %RDF.Graph{name: nil} = default_graph ->
        to_sparql_triples(update_form, default_graph, false, opts)

      named_graph ->
        with {:ok, triples} <- to_sparql_triples(update_form, named_graph, false, opts) do
          {:ok,
           """
           GRAPH <#{named_graph.name}> {
           #{triples}
           }
           """}
        end
    end)
  end

  defp to_sparql_triples(_, data, _, opts) do
    Turtle.write_string(data, Keyword.merge(opts, only: :triples))
  end

  defp sparql_update_data_keyword(:insert_data), do: "INSERT"
  defp sparql_update_data_keyword(:delete_data), do: "DELETE"

  @impl true
  def evaluate_response(_, _), do: :ok
end
