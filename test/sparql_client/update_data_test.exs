defmodule SPARQL.Client.UpdateDataTest do
  use ExUnit.Case

  alias SPARQL.Client.UpdateData

  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/sparql-cient-test#", terms: [], strict: false

  @example_endpoint "http://example.com/sparql"

  @example_description EX.Foo |> EX.bar(EX.Baz)
  @example_graph RDF.Graph.new(@example_description, prefixes: %{ex: EX})
                 |> RDF.Graph.add(EX.Other |> EX.p("string"))
  @example_dataset RDF.Dataset.new(@example_description)
                   |> RDF.Dataset.add({EX.Other, EX.p(), "string", EX.NamedGraph})

  describe "to_sparql/2" do
    test "with description" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-cient-test#Foo>
                  <http://example.com/sparql-cient-test#bar> <http://example.com/sparql-cient-test#Baz> .

              }
              """} = UpdateData.to_sparql(:insert, @example_description)
    end

    test "with graph" do
      assert {:ok,
              """
              PREFIX ex: <http://example.com/sparql-cient-test#>


              INSERT DATA {
              ex:Foo
                  ex:bar ex:Baz .

              ex:Other
                  ex:p "string" .

              }
              """} = UpdateData.to_sparql(:insert, @example_graph)
    end

    test "with dataset" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-cient-test#Foo>
                  <http://example.com/sparql-cient-test#bar> <http://example.com/sparql-cient-test#Baz> .

              GRAPH <http://example.com/sparql-cient-test#NamedGraph> {
              <http://example.com/sparql-cient-test#Other>
                  <http://example.com/sparql-cient-test#p> "string" .

              }

              }
              """} = UpdateData.to_sparql(:insert, @example_dataset)
    end

    test "with dataset and merge_graphs: true" do
      assert {:ok,
              """
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>


              INSERT DATA {
              <http://example.com/sparql-cient-test#Foo>
                  <http://example.com/sparql-cient-test#bar> <http://example.com/sparql-cient-test#Baz> .

              <http://example.com/sparql-cient-test#Other>
                  <http://example.com/sparql-cient-test#p> "string" .

              }
              """} = UpdateData.to_sparql(:insert, @example_dataset, merge_graphs: true)
    end

    test "with additional prefixes" do
      assert {:ok,
              """
              PREFIX ex: <http://example.com/sparql-cient-test#>


              INSERT DATA {
              ex:Foo
                  ex:bar ex:Baz .

              }
              """} = UpdateData.to_sparql(:insert, @example_description, prefixes: %{ex: EX})
    end
  end

  describe "insert_data/3" do
    test "direct POST" do
      mock_update_request(:direct, :insert, @example_description)
      assert SPARQL.Client.insert_data(@example_description, @example_endpoint) == :ok

      mock_update_request(:direct, :insert, @example_graph)
      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint) == :ok

      mock_update_request(:direct, :insert, @example_dataset)
      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint) == :ok
    end

    test "URL-encoded POST" do
      mock_update_request(:url_encoded, :insert, @example_description)

      assert SPARQL.Client.insert_data(@example_description, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :insert, @example_graph)

      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :insert, @example_dataset)

      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint,
               request_method: :url_encoded
             ) == :ok
    end
  end

  def mock_update_request(request_method, update_form, data, opts \\ [])

  def mock_update_request(:direct, update_form, data, opts) do
    {:ok, update} = UpdateData.to_sparql(update_form, data, opts)
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

  def mock_update_request(:url_encoded, update_form, data, opts) do
    {:ok, update} = UpdateData.to_sparql(update_form, data, opts)
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
end
