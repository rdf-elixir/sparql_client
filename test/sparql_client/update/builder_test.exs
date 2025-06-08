defmodule SPARQL.Client.Update.BuilderTest do
  use SPARQL.Client.Test.Case

  alias SPARQL.Client.Update.Builder

  @example_description EX.Foo |> EX.bar(EX.Baz)
  @example_graph RDF.Graph.new(@example_description, prefixes: %{ex: EX})
                 |> RDF.Graph.add(EX.Other |> EX.p("string"))
  @example_dataset RDF.Dataset.new(@example_graph)
                   |> RDF.Dataset.add(
                     RDF.Graph.new({EX.Another, EX.p(), ~I<http://example.com/2/foo>},
                       name: EX.NamedGraph,
                       prefixes: [ex2: "http://example.com/2/"]
                     )
                   )

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
              PREFIX ex: <http://example.com/sparql-client-test#>
              PREFIX ex2: <http://example.com/2/>

              INSERT DATA {
              ex:Foo
                  ex:bar ex:Baz .

              ex:Other
                  ex:p "string" .

              GRAPH <http://example.com/sparql-client-test#NamedGraph> {
              ex:Another
                  ex:p ex2:foo .

              }

              }
              """} = Builder.update_data(:insert_data, @example_dataset)
    end

    test "DELETE DATA with dataset" do
      assert {:ok,
              """
              PREFIX ex: <http://example.com/sparql-client-test#>
              PREFIX ex2: <http://example.com/2/>

              DELETE DATA {
              ex:Foo
                  ex:bar ex:Baz .

              ex:Other
                  ex:p "string" .

              GRAPH <http://example.com/sparql-client-test#NamedGraph> {
              ex:Another
                  ex:p ex2:foo .

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

  describe "load/3" do
    test "from IRI in string" do
      assert Builder.load(IRI.to_string(EX.Resource), nil, false) ==
               {:ok, "LOAD <#{IRI.to_string(EX.Resource)}>"}
    end

    test "from RDF.IRI" do
      assert Builder.load(RDF.iri(EX.Resource), nil, false) ==
               {:ok, "LOAD <#{IRI.to_string(EX.Resource)}>"}
    end

    test "from IRI as vocabulary term" do
      assert Builder.load(EX.Resource, nil, false) ==
               {:ok, "LOAD <#{IRI.to_string(EX.Resource)}>"}
    end

    test "into graph" do
      assert Builder.load(EX.Resource, EX.Graph, false) ==
               {:ok,
                "LOAD <#{IRI.to_string(EX.Resource)}> INTO GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.load(EX.Resource, nil, true) ==
               {:ok, "LOAD SILENT <#{IRI.to_string(EX.Resource)}>"}

      assert Builder.load(EX.Resource, EX.Graph, true) ==
               {:ok,
                "LOAD SILENT <#{IRI.to_string(EX.Resource)}> INTO GRAPH <#{IRI.to_string(EX.Graph)}>"}
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

    test "with list of graph IRIs" do
      assert Builder.clear(
               [IRI.to_string(EX.Graph1), RDF.iri(EX.Graph2), :default, EX.Graph3, :named],
               false
             ) ==
               {:ok,
                """
                CLEAR GRAPH <#{IRI.to_string(EX.Graph1)}>;
                CLEAR GRAPH <#{IRI.to_string(EX.Graph2)}>;
                CLEAR DEFAULT;
                CLEAR GRAPH <#{IRI.to_string(EX.Graph3)}>;
                CLEAR NAMED
                """
                |> String.trim_trailing()}
    end

    test "with list of graph IRIs and silent flag" do
      assert Builder.clear([EX.Graph1, EX.Graph2], true) ==
               {:ok,
                """
                CLEAR SILENT GRAPH <#{IRI.to_string(EX.Graph1)}>;
                CLEAR SILENT GRAPH <#{IRI.to_string(EX.Graph2)}>
                """
                |> String.trim_trailing()}
    end

    test "with single element list" do
      assert Builder.clear([EX.Graph], false) ==
               {:ok, "CLEAR GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with empty list" do
      assert Builder.clear([], false) == {:error, "no graphs to clear"}
    end
  end

  describe "drop/2" do
    test "with :default as graph" do
      assert Builder.drop(:default, false) == {:ok, "DROP DEFAULT"}
    end

    test "with :named as graph" do
      assert Builder.drop(:named, false) == {:ok, "DROP NAMED"}
    end

    test "with :all as graph" do
      assert Builder.drop(:all, false) == {:ok, "DROP ALL"}
    end

    test "with IRI string as graph" do
      assert Builder.drop(IRI.to_string(EX.Graph), false) ==
               {:ok, "DROP GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with RDF.IRI as graph" do
      assert Builder.drop(RDF.iri(EX.Graph), false) ==
               {:ok, "DROP GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with vocabulary term as graph" do
      assert Builder.drop(EX.Graph, false) ==
               {:ok, "DROP GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.drop(:default, true) == {:ok, "DROP SILENT DEFAULT"}

      assert Builder.drop(EX.Graph, true) ==
               {:ok, "DROP SILENT GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with list of graph IRIs" do
      assert Builder.drop(
               [IRI.to_string(EX.Graph1), RDF.iri(EX.Graph2), :default, EX.Graph3, :named],
               false
             ) ==
               {:ok,
                """
                DROP GRAPH <#{IRI.to_string(EX.Graph1)}>;
                DROP GRAPH <#{IRI.to_string(EX.Graph2)}>;
                DROP DEFAULT;
                DROP GRAPH <#{IRI.to_string(EX.Graph3)}>;
                DROP NAMED
                """
                |> String.trim_trailing()}
    end

    test "with list of graph IRIs and silent flag" do
      assert Builder.drop([EX.Graph1, EX.Graph2], true) ==
               {:ok,
                """
                DROP SILENT GRAPH <#{IRI.to_string(EX.Graph1)}>;
                DROP SILENT GRAPH <#{IRI.to_string(EX.Graph2)}>
                """
                |> String.trim_trailing()}
    end

    test "with single element list" do
      assert Builder.drop([EX.Graph], false) ==
               {:ok, "DROP GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with empty list" do
      assert Builder.drop([], false) == {:error, "no graphs to drop"}
    end
  end

  describe "create/2" do
    test "without silent flag" do
      assert Builder.create(EX.Graph, false) == {:ok, "CREATE GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.create(EX.Graph, true) ==
               {:ok, "CREATE SILENT GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with list of graph IRIs" do
      assert Builder.create(
               [IRI.to_string(EX.Graph1), RDF.iri(EX.Graph2), EX.Graph3],
               false
             ) ==
               {:ok,
                """
                CREATE GRAPH <#{IRI.to_string(EX.Graph1)}>;
                CREATE GRAPH <#{IRI.to_string(EX.Graph2)}>;
                CREATE GRAPH <#{IRI.to_string(EX.Graph3)}>
                """
                |> String.trim_trailing()}
    end

    test "with list of graph IRIs and silent flag" do
      assert Builder.create([EX.Graph1, EX.Graph2], true) ==
               {:ok,
                """
                CREATE SILENT GRAPH <#{IRI.to_string(EX.Graph1)}>;
                CREATE SILENT GRAPH <#{IRI.to_string(EX.Graph2)}>
                """
                |> String.trim_trailing()}
    end

    test "with single element list" do
      assert Builder.create([EX.Graph], false) ==
               {:ok, "CREATE GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with empty list" do
      assert Builder.create([], false) == {:error, "no graphs to create"}
    end
  end

  describe "copy/3" do
    test "with graph names as strings" do
      assert Builder.copy(IRI.to_string(EX.Graph1), IRI.to_string(EX.Graph2), false) ==
               {:ok,
                "COPY GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Graph2)}>"}
    end

    test "with graph names as RDF.IRIs" do
      assert Builder.copy(RDF.iri(EX.Graph1), RDF.iri(EX.Graph2), false) ==
               {:ok,
                "COPY GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Graph2)}>"}
    end

    test "with graph names as vocabulary terms" do
      assert Builder.copy(EX.Graph1, EX.Graph2, false) ==
               {:ok,
                "COPY GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Graph2)}>"}
    end

    test "with default graph" do
      assert Builder.copy(:default, EX.Graph, false) ==
               {:ok, "COPY DEFAULT TO GRAPH <#{IRI.to_string(EX.Graph)}>"}

      assert Builder.copy(EX.Graph, :default, false) ==
               {:ok, "COPY GRAPH <#{IRI.to_string(EX.Graph)}> TO DEFAULT"}
    end

    test "with silent flag" do
      assert Builder.copy(EX.Graph, :default, true) ==
               {:ok, "COPY SILENT GRAPH <#{IRI.to_string(EX.Graph)}> TO DEFAULT"}
    end
  end

  describe "move/3" do
    test "with graph names" do
      assert Builder.move(EX.Graph1, IRI.to_string(EX.Graph2), false) ==
               {:ok,
                "MOVE GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Graph2)}>"}
    end

    test "with default graph" do
      assert Builder.move(:default, EX.Graph, false) ==
               {:ok, "MOVE DEFAULT TO GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.move(EX.Graph, :default, true) ==
               {:ok, "MOVE SILENT GRAPH <#{IRI.to_string(EX.Graph)}> TO DEFAULT"}
    end
  end

  describe "add/3" do
    test "with graph names" do
      assert Builder.add(EX.Graph1, IRI.to_string(EX.Graph2), false) ==
               {:ok,
                "ADD GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Graph2)}>"}
    end

    test "with default graph" do
      assert Builder.add(:default, EX.Graph, false) ==
               {:ok, "ADD DEFAULT TO GRAPH <#{IRI.to_string(EX.Graph)}>"}
    end

    test "with silent flag" do
      assert Builder.add(EX.Graph, :default, true) ==
               {:ok, "ADD SILENT GRAPH <#{IRI.to_string(EX.Graph)}> TO DEFAULT"}
    end

    test "with list of source graphs" do
      assert Builder.add(
               [IRI.to_string(EX.Graph1), RDF.iri(EX.Graph2), :default, EX.Graph3],
               EX.Target,
               false
             ) ==
               {:ok,
                """
                ADD GRAPH <#{IRI.to_string(EX.Graph1)}> TO GRAPH <#{IRI.to_string(EX.Target)}>;
                ADD GRAPH <#{IRI.to_string(EX.Graph2)}> TO GRAPH <#{IRI.to_string(EX.Target)}>;
                ADD DEFAULT TO GRAPH <#{IRI.to_string(EX.Target)}>;
                ADD GRAPH <#{IRI.to_string(EX.Graph3)}> TO GRAPH <#{IRI.to_string(EX.Target)}>
                """
                |> String.trim_trailing()}
    end

    test "with list of source graphs and silent flag" do
      assert Builder.add([EX.Graph1, EX.Graph2], :default, true) ==
               {:ok,
                """
                ADD SILENT GRAPH <#{IRI.to_string(EX.Graph1)}> TO DEFAULT;
                ADD SILENT GRAPH <#{IRI.to_string(EX.Graph2)}> TO DEFAULT
                """
                |> String.trim_trailing()}
    end

    test "with single element list" do
      assert Builder.add([EX.Graph], EX.Target, false) ==
               {:ok,
                "ADD GRAPH <#{IRI.to_string(EX.Graph)}> TO GRAPH <#{IRI.to_string(EX.Target)}>"}
    end

    test "with empty list" do
      assert Builder.add([], EX.Target, false) == {:error, "no graphs to add"}
    end
  end
end
