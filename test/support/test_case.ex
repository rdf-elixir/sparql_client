defmodule SPARQL.Client.Test.Case do
  use ExUnit.CaseTemplate

  use RDF.Vocabulary.Namespace

  defvocab EX,
    base_iri: "http://example.com/sparql-client-test#",
    terms: [],
    strict: false

  using do
    quote do
      import RDF.Sigils
      import unquote(__MODULE__)

      alias RDF.IRI
      alias unquote(__MODULE__).EX

      @compile {:no_warn_undefined, SPARQL.Client.Test.Case.EX}
    end
  end

  def assert_equal_graph(expected, actual) do
    assert {:ok, graph} = actual
    assert RDF.Graph.equal?(expected, graph)
  end
end
