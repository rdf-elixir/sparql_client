defmodule SPARQL.Client.Update.Builder do
  @moduledoc false

  import SPARQL.Client.Utils
  alias RDF.Turtle

  def update_data(update_form, data, opts \\ []) do
    with {:ok, prologue} <-
           Turtle.write_string(
             data,
             Keyword.merge(opts, only: :directives, directive_style: :sparql)
           ),
         {:ok, triples} <-
           update_data_triples(update_form, data, Keyword.get(opts, :merge_graphs, false), opts) do
      {:ok,
       """
       #{prologue}
       #{sparql_update_data_keyword(update_form)} DATA {
       #{triples}
       }
       """}
    end
  end

  defp update_data_triples(update_form, %RDF.Dataset{} = dataset, false, opts) do
    dataset
    |> RDF.Dataset.graphs()
    |> map_join_while_ok("\n", fn
      %RDF.Graph{name: nil} = default_graph ->
        update_data_triples(update_form, default_graph, false, opts)

      named_graph ->
        with {:ok, triples} <- update_data_triples(update_form, named_graph, false, opts) do
          {:ok,
           """
           GRAPH <#{named_graph.name}> {
           #{triples}
           }
           """}
        end
    end)
  end

  defp update_data_triples(_, data, _, opts) do
    Turtle.write_string(data, Keyword.merge(opts, only: :triples))
  end

  defp sparql_update_data_keyword(:insert_data), do: "INSERT"
  defp sparql_update_data_keyword(:delete_data), do: "DELETE"
end
