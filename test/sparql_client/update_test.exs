defmodule SPARQL.Client.UpdateTest do
  use SPARQL.Client.Test.Case

  alias SPARQL.Client.Update

  @example_endpoint "http://example.com/sparql"

  @example_description EX.Foo |> EX.bar(EX.Baz)
  @example_graph RDF.Graph.new(@example_description, prefixes: %{ex: EX})
                 |> RDF.Graph.add(EX.Other |> EX.p("string"))
  @example_dataset RDF.Dataset.new(@example_description)
                   |> RDF.Dataset.add({EX.Other, EX.p(), "string", EX.NamedGraph})

  describe "update/3" do
    test "with passing an update string directly in raw-mode" do
      update = """
      PREFIX dc:  <http://purl.org/dc/elements/1.1/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      INSERT
      { GRAPH <http://example/bookStore2> { ?book ?p ?v } }
      WHERE
      { GRAPH  <http://example/bookStore>
       { ?book dc:date ?date .
         FILTER ( ?date > "1970-01-01T00:00:00-02:00"^^xsd:dateTime )
         ?book ?p ?v
      } }
      """

      mock_update_request(:direct, update)
      assert SPARQL.Client.update(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "insert/3" do
    test "with passing an update string directly in raw-mode" do
      update = """
      PREFIX dc:  <http://purl.org/dc/elements/1.1/>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      INSERT
      { GRAPH <http://example/bookStore2> { ?book ?p ?v } }
      WHERE
      { GRAPH  <http://example/bookStore>
       { ?book dc:date ?date .
         FILTER ( ?date > "1970-01-01T00:00:00-02:00"^^xsd:dateTime )
         ?book ?p ?v
      } }
      """

      mock_update_request(:direct, update)
      assert SPARQL.Client.insert(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "delete/3" do
    test "with passing an update string directly in raw-mode" do
      update = """
      PREFIX foaf:  <http://xmlns.com/foaf/0.1/>

      WITH <http://example/addresses>
      DELETE { ?person ?property ?value }
      WHERE { ?person ?property ?value ; foaf:givenName 'Fred' }
      """

      mock_update_request(:direct, update)
      assert SPARQL.Client.delete(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "insert_data/3" do
    test "direct POST" do
      mock_update_data_request(:direct, :insert_data, @example_description)
      assert SPARQL.Client.insert_data(@example_description, @example_endpoint) == :ok

      mock_update_data_request(:direct, :insert_data, @example_graph)
      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint) == :ok

      mock_update_data_request(:direct, :insert_data, @example_dataset)
      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint) == :ok
    end

    test "URL-encoded POST" do
      mock_update_data_request(:url_encoded, :insert_data, @example_description)

      assert SPARQL.Client.insert_data(@example_description, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_data_request(:url_encoded, :insert_data, @example_graph)

      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_data_request(:url_encoded, :insert_data, @example_dataset)

      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint,
               request_method: :url_encoded
             ) == :ok
    end

    test "with passing an update string directly in raw-mode" do
      {:ok, update} = Update.Builder.update_data(:insert_data, @example_graph)
      mock_update_data_request(:direct, :insert_data, @example_graph)
      assert SPARQL.Client.insert_data(update, @example_endpoint, raw_mode: true) == :ok

      {:ok, update} = Update.Builder.update_data(:insert_data, @example_dataset)

      mock_update_data_request(:url_encoded, :insert_data, @example_dataset)

      assert SPARQL.Client.insert_data(update, @example_endpoint,
               request_method: :url_encoded,
               raw_mode: true
             ) ==
               :ok
    end
  end

  describe "delete_data/3" do
    test "direct POST" do
      mock_update_data_request(:direct, :delete_data, @example_description)
      assert SPARQL.Client.delete_data(@example_description, @example_endpoint) == :ok

      mock_update_data_request(:direct, :delete_data, @example_graph)
      assert SPARQL.Client.delete_data(@example_graph, @example_endpoint) == :ok

      mock_update_data_request(:direct, :delete_data, @example_dataset)
      assert SPARQL.Client.delete_data(@example_dataset, @example_endpoint) == :ok
    end

    test "URL-encoded POST" do
      mock_update_data_request(:url_encoded, :delete_data, @example_description)

      assert SPARQL.Client.delete_data(@example_description, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_data_request(:url_encoded, :delete_data, @example_graph)

      assert SPARQL.Client.delete_data(@example_graph, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_data_request(:url_encoded, :delete_data, @example_dataset)

      assert SPARQL.Client.delete_data(@example_dataset, @example_endpoint,
               request_method: :url_encoded
             ) == :ok
    end

    test "with passing an update string directly in raw-mode" do
      {:ok, update} = Update.Builder.update_data(:delete_data, @example_graph)
      mock_update_data_request(:direct, :delete_data, @example_graph)
      assert SPARQL.Client.delete_data(update, @example_endpoint, raw_mode: true) == :ok

      {:ok, update} = Update.Builder.update_data(:delete_data, @example_description)

      mock_update_data_request(:url_encoded, :delete_data, @example_description)

      assert SPARQL.Client.delete_data(update, @example_endpoint,
               request_method: :url_encoded,
               raw_mode: true
             ) ==
               :ok
    end
  end

  describe "load/2" do
    test "with :from option" do
      update = "LOAD <http://example.com/sparql-client-test#Resource>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.load(@example_endpoint, from: EX.Resource) == :ok
    end

    test "with :to option" do
      update =
        "LOAD <http://example.com/sparql-client-test#Resource> INTO GRAPH <http://example.com/sparql-client-test#Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.load(@example_endpoint, from: EX.Resource, to: EX.Graph) == :ok
    end

    test "with :silent option" do
      mock_update_request(:direct, "LOAD SILENT <http://example.com/sparql-client-test#Resource>")
      assert SPARQL.Client.load(@example_endpoint, from: EX.Resource, silent: true) == :ok
    end
  end

  describe "load/3" do
    test "with :from, :to or :silent option and a query" do
      assert_raise ArgumentError,
                   "load/3 does not support the :from, :to and :silent options; use load/2 instead",
                   fn ->
                     SPARQL.Client.load("LOAD <foo>", @example_endpoint, from: EX.Resource)
                   end

      assert_raise ArgumentError,
                   "load/3 does not support the :from, :to and :silent options; use load/2 instead",
                   fn -> SPARQL.Client.load("CLEAR ALL", @example_endpoint, silent: true) end
    end

    test "with passing an update string directly in raw-mode" do
      update = "LOAD <http://example.com/Resource>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.load(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "clear/2" do
    test "with :graph option" do
      update = "CLEAR GRAPH <http://example.com/sparql-client-test#Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.clear(@example_endpoint, graph: EX.Graph) == :ok
    end

    test "with :silent option" do
      mock_update_request(:direct, "CLEAR SILENT DEFAULT")
      assert SPARQL.Client.clear(@example_endpoint, graph: :default, silent: true) == :ok
    end
  end

  describe "clear/3" do
    test "with :graph or :silent option and a query" do
      assert_raise ArgumentError,
                   "clear/3 does not support the :graph and :silent options; use clear/2 instead",
                   fn -> SPARQL.Client.clear("CLEAR ALL", @example_endpoint, graph: :default) end

      assert_raise ArgumentError,
                   "clear/3 does not support the :graph and :silent options; use clear/2 instead",
                   fn -> SPARQL.Client.clear("CLEAR ALL", @example_endpoint, silent: true) end
    end

    test "with passing an update string directly in raw-mode" do
      update = "CLEAR GRAPH <http://example.com/Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.clear(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "drop/2" do
    test "with :graph option" do
      update = "DROP GRAPH <http://example.com/sparql-client-test#Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.drop(@example_endpoint, graph: EX.Graph) == :ok
    end

    test "with :silent option" do
      mock_update_request(:direct, "DROP SILENT DEFAULT")
      assert SPARQL.Client.drop(@example_endpoint, graph: :default, silent: true) == :ok
    end
  end

  describe "drop/3" do
    test "with :graph or :silent option and a query" do
      assert_raise ArgumentError,
                   "drop/3 does not support the :graph and :silent options; use drop/2 instead",
                   fn -> SPARQL.Client.drop("DROP ALL", @example_endpoint, graph: :default) end

      assert_raise ArgumentError,
                   "drop/3 does not support the :graph and :silent options; use drop/2 instead",
                   fn -> SPARQL.Client.drop("DROP ALL", @example_endpoint, silent: true) end
    end

    test "with passing an update string directly in raw-mode" do
      update = "DROP GRAPH <http://example.com/Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.drop(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "create/2" do
    test "with :graph option" do
      update = "CREATE GRAPH <http://example.com/sparql-client-test#Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.create(@example_endpoint, graph: EX.Graph) == :ok
    end

    test "with :silent option" do
      mock_update_request(
        :direct,
        "CREATE SILENT GRAPH <http://example.com/sparql-client-test#Graph>"
      )

      assert SPARQL.Client.create(@example_endpoint, graph: EX.Graph, silent: true) == :ok
    end
  end

  describe "create/3" do
    test "with :graph or :silent option and a query" do
      assert_raise ArgumentError,
                   "create/3 does not support the :graph and :silent options; use create/2 instead",
                   fn -> SPARQL.Client.create("CREATE", @example_endpoint, graph: :default) end

      assert_raise ArgumentError,
                   "create/3 does not support the :graph and :silent options; use create/2 instead",
                   fn -> SPARQL.Client.create("CREATE", @example_endpoint, silent: true) end
    end

    test "with passing an update string directly in raw-mode" do
      update = "CREATE GRAPH <http://example.com/Graph>"

      mock_update_request(:direct, update)
      assert SPARQL.Client.create(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "copy/2" do
    test "with :from and :to option" do
      update = "COPY GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.copy(@example_endpoint, from: EX.Graph1, to: :default) == :ok
    end

    test "with :silent option" do
      update = "COPY SILENT DEFAULT TO GRAPH <http://example.com/sparql-client-test#Graph>"
      mock_update_request(:direct, update)

      assert SPARQL.Client.copy(@example_endpoint, from: :default, to: EX.Graph, silent: true) ==
               :ok
    end
  end

  describe "copy/3" do
    test "with :from, :to or :silent option and a query" do
      assert_raise ArgumentError,
                   "copy/3 does not support the :from, :to and :silent options; use copy/2 instead",
                   fn ->
                     SPARQL.Client.copy("COPY", @example_endpoint, from: EX.Graph1, to: EX.Graph2)
                   end

      assert_raise ArgumentError,
                   "copy/3 does not support the :from, :to and :silent options; use copy/2 instead",
                   fn -> SPARQL.Client.copy("COPY", @example_endpoint, silent: true) end
    end

    test "with passing an update string directly in raw-mode" do
      update = "COPY GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.copy(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "move/2" do
    test "with :from and :to option" do
      update = "MOVE GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.move(@example_endpoint, from: EX.Graph1, to: :default) == :ok
    end

    test "with :silent option" do
      update = "MOVE SILENT DEFAULT TO GRAPH <http://example.com/sparql-client-test#Graph>"
      mock_update_request(:direct, update)

      assert SPARQL.Client.move(@example_endpoint, from: :default, to: EX.Graph, silent: true) ==
               :ok
    end
  end

  describe "move/3" do
    test "with :from, :to or :silent option and a query" do
      assert_raise ArgumentError,
                   "move/3 does not support the :from, :to and :silent options; use move/2 instead",
                   fn ->
                     SPARQL.Client.move("MOVE", @example_endpoint, from: EX.Graph1, to: EX.Graph2)
                   end
    end

    test "with passing an update string directly in raw-mode" do
      update = "MOVE GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.move(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "add/2" do
    test "with :from and :to option" do
      update = "ADD GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.add(@example_endpoint, from: EX.Graph1, to: :default) == :ok
    end

    test "with :silent option" do
      update = "ADD SILENT DEFAULT TO GRAPH <http://example.com/sparql-client-test#Graph>"
      mock_update_request(:direct, update)

      assert SPARQL.Client.add(@example_endpoint, from: :default, to: EX.Graph, silent: true) ==
               :ok
    end
  end

  describe "add/3" do
    test "with :from, :to or :silent option and a query" do
      assert_raise ArgumentError,
                   "add/3 does not support the :from, :to and :silent options; use add/2 instead",
                   fn ->
                     SPARQL.Client.add("ADD", @example_endpoint, from: EX.Graph1, to: EX.Graph2)
                   end
    end

    test "with passing an update string directly in raw-mode" do
      update = "ADD GRAPH <http://example.com/sparql-client-test#Graph1> TO DEFAULT"

      mock_update_request(:direct, update)
      assert SPARQL.Client.add(update, @example_endpoint, raw_mode: true) == :ok
    end
  end

  describe "specifying an RDF Dataset" do
    @graph_uri "http://www.other.example/sparql/"

    @example_update """
    PREFIX dc:  <http://purl.org/dc/elements/1.1/>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

    INSERT
    { GRAPH <http://example/bookStore2> { ?book ?p ?v } }
    WHERE
    { GRAPH  <http://example/bookStore>
     { ?book dc:date ?date .
       FILTER ( ?date > "1970-01-01T00:00:00-02:00"^^xsd:dateTime )
       ?book ?p ?v
    } }
    """

    test "using default and named graphs via direct POST" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"using-graph-uri", @graph_uri <> "1"},
            {"using-named-graph-uri", @graph_uri <> "2"},
            {"using-named-graph-uri", @graph_uri <> "3"}
          ])

      Tesla.Mock.mock(fn
        env = %{method: :post, url: ^url, body: @example_update} ->
          assert Tesla.get_header(env, "Content-Type") == "application/sparql-update"

          %Tesla.Env{
            status: 204,
            body: ""
          }
      end)

      assert SPARQL.Client.insert(@example_update, @example_endpoint,
               request_method: :direct,
               using_graph: @graph_uri <> "1",
               using_named_graph: [@graph_uri <> "2", @graph_uri <> "3"],
               raw_mode: true
             ) ==
               :ok
    end

    test "using default and named graphs via URL-encoded POST" do
      body =
        URI.encode_query([
          {"update", @example_update},
          {"using-graph-uri", @graph_uri <> "1"},
          {"using-named-graph-uri", @graph_uri <> "2"},
          {"using-named-graph-uri", @graph_uri <> "3"}
        ])

      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"

          %Tesla.Env{
            status: 204,
            body: ""
          }
      end)

      assert SPARQL.Client.insert(@example_update, @example_endpoint,
               request_method: :url_encoded,
               using_graph: @graph_uri <> "1",
               using_named_graph: [@graph_uri <> "2", @graph_uri <> "3"],
               raw_mode: true
             ) ==
               :ok
    end
  end

  def mock_update_request(request_method, update, opts \\ [])

  def mock_update_request(:direct, update, opts) do
    endpoint = Keyword.get(opts, :endpoint, @example_endpoint)

    Tesla.Mock.mock(fn
      env = %{method: :post, url: ^endpoint, body: ^update} ->
        assert Tesla.get_header(env, "Content-Type") == "application/sparql-update"

        %Tesla.Env{
          status: Keyword.get(opts, :status, 204),
          body: Keyword.get(opts, :response, "")
        }
    end)
  end

  def mock_update_request(:url_encoded, update, opts) do
    update_query_param = URI.encode_query(%{update: update})
    endpoint = Keyword.get(opts, :endpoint, @example_endpoint)

    Tesla.Mock.mock(fn
      env = %{method: :post, url: ^endpoint, body: ^update_query_param} ->
        assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"

        %Tesla.Env{
          status: Keyword.get(opts, :status, 204),
          body: Keyword.get(opts, :response, "")
        }
    end)
  end

  def mock_update_data_request(request_method, update_form, data, opts \\ []) do
    {:ok, update} = Update.Builder.update_data(update_form, data, opts)
    mock_update_request(request_method, update, opts)
  end
end
