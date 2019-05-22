defmodule SPARQL.Client.Test.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import RDF.Sigils

      import unquote(__MODULE__)
    end
  end

  def assert_equal_graph(expected, actual) do
    assert {:ok, graph} = actual
    assert RDF.Graph.equal?(expected, graph)
  end
end
