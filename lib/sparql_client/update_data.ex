defmodule SPARQL.Client.UpdateData do
  @doc false

  @behaviour SPARQL.Client.Operation

  alias RDF.Turtle
  import SPARQL.Client.Utils

  @impl true
  def query_parameter_key, do: "update"

  @impl true
  def init(request, {update_type, data}, opts) do
    with {:ok, protocol_version, request_method} <-
           opts |> Keyword.get(:request_method) |> request_method() do
      {:ok,
       %{
         request
         | sparql_operation_type: __MODULE__,
           sparql_operation: data,
           sparql_operation_form: update_type,
           sparql_protocol_version: protocol_version,
           http_method: request_method,
           http_content_type_header: content_type(protocol_version, request_method)
       }
       |> add_headers(opts)}
    end
  end

  defp request_method(:direct), do: {:ok, "1.1", :post}
  defp request_method(:url_encoded), do: {:ok, "1.0", :post}

  defp content_type("1.1", :post), do: "application/sparql-update"
  defp content_type("1.0", :post), do: "application/x-www-form-urlencoded"
  defp content_type(_, _), do: nil

  defp add_headers(request, opts) do
    %{
      request
      | http_headers:
          %{
            "Content-Type" => request.http_content_type_header
          }
          |> Map.merge(Keyword.get(opts, :headers, %{}))
    }
  end

  @impl true
  def operation_string(request, opts) do
    to_sparql(request.sparql_operation_form, request.sparql_operation, opts)
  end

  def to_sparql(update_form, data, opts \\ [])

  def to_sparql(:insert, data, opts) do
    with {:ok, prologue} <-
           Turtle.write_string(
             data,
             Keyword.merge(opts, only: :directives, directive_style: :sparql)
           ),
         {:ok, triples} <-
           to_sparql_triples(data, Keyword.get(opts, :merge_graphs, false), opts) do
      {:ok,
       """
       #{prologue}
       INSERT DATA {
       #{triples}
       }
       """}
    end
  end

  defp to_sparql_triples(%RDF.Dataset{} = dataset, false, opts) do
    dataset
    |> RDF.Dataset.graphs()
    |> map_join_while_ok("\n", fn
      %RDF.Graph{name: nil} = default_graph ->
        to_sparql_triples(default_graph, false, opts)

      named_graph ->
        with {:ok, triples} <- to_sparql_triples(named_graph, false, opts) do
          {:ok,
           """
           GRAPH <#{named_graph.name}> {
           #{triples}
           }
           """}
        end
    end)
  end

  defp to_sparql_triples(data, _, opts) do
    Turtle.write_string(data, Keyword.merge(opts, only: :triples))
  end

  @impl true
  def evaluate_response(_, _), do: :ok
end
