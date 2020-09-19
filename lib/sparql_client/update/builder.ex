defmodule SPARQL.Client.Update.Builder do
  @moduledoc false

  import SPARQL.Client.Utils
  import RDF.Guards
  alias RDF.{IRI, Turtle}

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

  def load(from, to, silent) do
    {:ok, "LOAD " <> silent_fragment(silent) <> iri_ref(from) <> into_graph_fragment(to)}
  end

  def clear(graph_iri, silent) do
    {:ok, "CLEAR " <> silent_fragment(silent) <> clear_graph_fragment(graph_iri)}
  end

  defp into_graph_fragment(nil), do: ""
  defp into_graph_fragment(iri), do: " INTO GRAPH #{iri_ref(iri)}"

  defp clear_graph_fragment(:default), do: "DEFAULT"
  defp clear_graph_fragment(:named), do: "NAMED"
  defp clear_graph_fragment(:all), do: "ALL"
  defp clear_graph_fragment(iri), do: "GRAPH #{iri_ref(iri)}"

  defp silent_fragment(true), do: "SILENT "
  defp silent_fragment(_), do: ""

  defp iri_ref(iri) when is_binary(iri), do: "<#{iri}>"
  defp iri_ref(%IRI{} = iri), do: iri |> IRI.to_string() |> iri_ref()
  defp iri_ref(term) when maybe_ns_term(term), do: term |> IRI.to_string() |> iri_ref()
end
