defmodule SPARQL.Client.Update.Builder do
  @moduledoc false

  import RDF.Utils
  import RDF.Guards
  alias RDF.{IRI, Turtle, Graph, Dataset}

  def update_data(update_form, data, opts \\ []) do
    {prefixes, opts} = Keyword.pop(opts, :prefixes)

    with {:ok, data} <- setup_prefixes(data, prefixes),
         {:ok, prologue} <- update_prologue(data, opts),
         {:ok, triples} <- update_data_triples(update_form, data, opts) do
      {:ok,
       """
       #{prologue}
       #{update_data_keyword(update_form)} DATA {
       #{triples}
       }
       """}
    end
  end

  defp setup_prefixes(%Dataset{} = dataset, nil) do
    setup_prefixes(dataset, Dataset.prefixes(dataset))
  end

  defp setup_prefixes(%Dataset{} = dataset, prefixes) do
    {:ok,
     dataset
     |> Dataset.graphs()
     |> Enum.reduce(dataset, fn graph, dataset ->
       Dataset.update(dataset, graph.name, &Graph.add_prefixes(&1, prefixes))
     end)}
  end

  defp setup_prefixes(data, nil), do: {:ok, data}

  defp setup_prefixes(data, prefixes) do
    {:ok, Graph.new(data, prefixes: prefixes)}
  end

  defp update_prologue(nil, _), do: ""

  defp update_prologue(%Dataset{} = dataset, opts) do
    dataset
    |> Dataset.graphs()
    |> List.first()
    |> update_prologue(opts)
  end

  defp update_prologue(graph, opts) do
    Turtle.write_string(
      graph,
      Keyword.merge(opts, content: :directives, directive_style: :sparql)
    )
  end

  defp update_data_triples(update_form, %Dataset{} = dataset, opts) do
    dataset
    |> Dataset.graphs()
    |> map_join_while_ok("\n", fn
      %Graph{name: nil} = default_graph ->
        update_data_triples(update_form, default_graph, opts)

      named_graph ->
        with {:ok, triples} <- update_data_triples(update_form, named_graph, opts) do
          {:ok,
           """
           GRAPH <#{named_graph.name}> {
           #{triples}
           }
           """}
        end
    end)
  end

  defp update_data_triples(_, data, opts) do
    Turtle.write_string(data, Keyword.merge(opts, content: :triples))
  end

  def load(from, to, silent) do
    {:ok, "LOAD " <> silent_fragment(silent) <> graph_ref(from) <> into_graph_fragment(to)}
  end

  def clear([], _silent), do: {:error, "no graphs to clear"}

  def clear(graph_iris, silent) when is_list(graph_iris) do
    with {:ok, updates} <-
           RDF.Utils.map_while_ok(graph_iris, &clear(&1, silent)) do
      {:ok, Enum.join(updates, ";\n")}
    end
  end

  def clear(graph_iri, silent) do
    {:ok, "CLEAR " <> silent_fragment(silent) <> clear_graph_identifier(graph_iri)}
  end

  def create([], _silent), do: {:error, "no graphs to create"}

  def create(graph_iris, silent) when is_list(graph_iris) do
    with {:ok, updates} <-
           RDF.Utils.map_while_ok(graph_iris, &create(&1, silent)) do
      {:ok, Enum.join(updates, ";\n")}
    end
  end

  def create(graph_iri, silent) do
    {:ok, "CREATE " <> silent_fragment(silent) <> "GRAPH #{graph_ref(graph_iri)}"}
  end

  def drop([], _silent), do: {:error, "no graphs to drop"}

  def drop(graph_iris, silent) when is_list(graph_iris) do
    with {:ok, updates} <-
           RDF.Utils.map_while_ok(graph_iris, &drop(&1, silent)) do
      {:ok, Enum.join(updates, ";\n")}
    end
  end

  def drop(graph_iri, silent) do
    {:ok, "DROP " <> silent_fragment(silent) <> clear_graph_identifier(graph_iri)}
  end

  def copy(from, to, silent) do
    graph_update(:copy, from, to, silent)
  end

  def move(from, to, silent) do
    graph_update(:move, from, to, silent)
  end

  def add([], _to, _silent), do: {:error, "no graphs to add"}

  def add(from_graphs, to, silent) when is_list(from_graphs) do
    with {:ok, updates} <-
           RDF.Utils.map_while_ok(from_graphs, &add(&1, to, silent)) do
      {:ok, Enum.join(updates, ";\n")}
    end
  end

  def add(from, to, silent) do
    graph_update(:add, from, to, silent)
  end

  def graph_update(update_form, from, to, silent) do
    {:ok,
     "#{graph_update_keyword(update_form)} " <>
       silent_fragment(silent) <> "#{graph_identifier(from)} TO #{graph_identifier(to)}"}
  end

  defp update_data_keyword(:insert_data), do: "INSERT"
  defp update_data_keyword(:delete_data), do: "DELETE"

  defp graph_update_keyword(:copy), do: "COPY"
  defp graph_update_keyword(:move), do: "MOVE"
  defp graph_update_keyword(:add), do: "ADD"

  defp into_graph_fragment(nil), do: ""
  defp into_graph_fragment(iri), do: " INTO GRAPH #{graph_ref(iri)}"

  defp clear_graph_identifier(:default), do: "DEFAULT"
  defp clear_graph_identifier(:named), do: "NAMED"
  defp clear_graph_identifier(:all), do: "ALL"
  defp clear_graph_identifier(iri), do: "GRAPH #{graph_ref(iri)}"

  defp graph_identifier(:default), do: "DEFAULT"
  defp graph_identifier(iri), do: "GRAPH #{graph_ref(iri)}"

  defp silent_fragment(true), do: "SILENT "
  defp silent_fragment(_), do: ""

  defp graph_ref(iri) when is_binary(iri), do: "<#{iri}>"
  defp graph_ref(%IRI{} = iri), do: iri |> IRI.to_string() |> graph_ref()
  defp graph_ref(term) when maybe_ns_term(term), do: term |> IRI.to_string() |> graph_ref()

  defp graph_ref(%RDF.BlankNode{} = bnode),
    do:
      raise(
        ArgumentError,
        "invalid graph reference: #{inspect(bnode)} (blank nodes are not allowed in SPARQL)"
      )

  defp graph_ref(invalid),
    do: raise(ArgumentError, "invalid graph reference: #{inspect(invalid)} ")
end
