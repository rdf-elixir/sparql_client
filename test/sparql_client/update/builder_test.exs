defmodule SPARQL.Client.Update.BuilderTest do
  use SPARQL.Client.Test.Case

  alias SPARQL.Client.Update.Builder

  @example_description EX.Foo |> EX.bar(EX.Baz)
  @example_graph RDF.Graph.new(@example_description, prefixes: %{ex: EX})
                 |> RDF.Graph.add(EX.Other |> EX.p("string"))
  @example_dataset RDF.Dataset.new(@example_description)
                   |> RDF.Dataset.add({EX.Other, EX.p(), "string", EX.NamedGraph})

  describe "update_data/3" do
    test "INSERT DATA with description" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-client-test#Foo>
                  <http://example.com/sparql-client-test#bar> <http://example.com/sparql-client-test#Baz> .

              }
              """} = Builder.update_data(:insert_data, @example_description)
    end

    test "INSERT DATA with graph" do
      assert {:ok,
              """
              PREFIX ex: <http://example.com/sparql-client-test#>


              INSERT DATA {
              ex:Foo
                  ex:bar ex:Baz .

              ex:Other
                  ex:p "string" .

              }
              """} = Builder.update_data(:insert_data, @example_graph)
    end

    test "INSERT DATA with dataset" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-client-test#Foo>
                  <http://example.com/sparql-client-test#bar> <http://example.com/sparql-client-test#Baz> .

              GRAPH <http://example.com/sparql-client-test#NamedGraph> {
              <http://example.com/sparql-client-test#Other>
                  <http://example.com/sparql-client-test#p> "string" .

              }

              }
              """} = Builder.update_data(:insert_data, @example_dataset)
    end

    test "INSERT DATA with dataset and merge_graphs: true" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-client-test#Foo>
                  <http://example.com/sparql-client-test#bar> <http://example.com/sparql-client-test#Baz> .

              <http://example.com/sparql-client-test#Other>
                  <http://example.com/sparql-client-test#p> "string" .

              }
              """} = Builder.update_data(:insert_data, @example_dataset, merge_graphs: true)
    end

    test "DELETE DATA with dataset" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              DELETE DATA {
              <http://example.com/sparql-client-test#Foo>
                  <http://example.com/sparql-client-test#bar> <http://example.com/sparql-client-test#Baz> .

              GRAPH <http://example.com/sparql-client-test#NamedGraph> {
              <http://example.com/sparql-client-test#Other>
                  <http://example.com/sparql-client-test#p> "string" .

              }

              }
              """} = Builder.update_data(:delete_data, @example_dataset)
    end

    test "with additional prefixes" do
      assert {:ok,
              """
              PREFIX ex: <http://example.com/sparql-client-test#>


              INSERT DATA {
              ex:Foo
                  ex:bar ex:Baz .

              }
              """} = Builder.update_data(:insert_data, @example_description, prefixes: %{ex: EX})
    end
  end

  describe "clear/2" do
    test "with :default as graph" do
      assert Builder.clear(:default, false) == {:ok, "CLEAR DEFAULT"}
    end

    test "with :named as graph" do
      assert Builder.clear(:named, false) == {:ok, "CLEAR NAMED"}
    end

    test "with :all as graph" do
      assert Builder.clear(:all, false) == {:ok, "CLEAR ALL"}
    end

    test "with IRI string as graph" do
      assert Builder.clear(IRI.to_string(EX.Graph), false) ==
               {:ok, "CLEAR GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with RDF.IRI as graph" do
      assert Builder.clear(RDF.iri(EX.Graph), false) ==
               {:ok, "CLEAR GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with vocabulary term as graph" do
      assert Builder.clear(EX.Graph, false) ==
               {:ok, "CLEAR GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.clear(:default, true) == {:ok, "CLEAR SILENT DEFAULT"}

      assert Builder.clear(EX.Graph, true) ==
               {:ok, "CLEAR SILENT GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end
  end
end
