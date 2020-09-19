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
