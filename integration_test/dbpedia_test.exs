# Issues with the DBpedia SPARQL endpoint:
#
# - It seems there's a problem with SPARQL protocol request via POST directly method:
#   https://www.mail-archive.com/virtuoso-users@lists.sourceforge.net/msg07984.html
# - The currently deployed version does not return spec-conform SPARQL 1.1 TSV results,
#   but just CSV with tabs as separators
# - The Turtle results are rather crappy since it almost always is invalid, like
#   rdf:langString literals without a language tag, invalid characters in prefixed names etc.

defmodule SPARQL.Client.DBpediaTest do
  use ExUnit.Case # In case test behaves unstable: , async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest SPARQL.Client

  alias SPARQL.Query
  import RDF.Sigils


  @dbpedia "http://dbpedia.org/sparql"


  describe "SELECT query" do
    @result_count 3

    @test_select_query """
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      PREFIX : <http://dbpedia.org/resource/>
      PREFIX dbo: <http://dbpedia.org/ontology/>

      SELECT ?name ?birth ?death ?person
      WHERE {
        ?person
          foaf:name      ?name ;
          dbo:birthPlace :Berlin ;
          dbo:birthDate  ?birth ;
          dbo:deathDate  ?death .
        FILTER (?birth < "1900-01-01"^^xsd:date) .
      }
      ORDER BY ?name
      LIMIT #{@result_count}
      """

    test "SELECT query with defaults" do
      use_cassette "dbpedia_select_via_defaults" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia)
        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via get" do
      use_cassette "dbpedia_select_as_json_via_get" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :json)
        assert Enum.count(result.results) == @result_count
      end
    end

    test "XML result via get" do
      use_cassette "dbpedia_select_as_xml_via_get" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :xml)
        assert Enum.count(result.results) == @result_count
      end
    end

    test "CSV result via get" do
      use_cassette "dbpedia_select_as_csv_via_get" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :csv)
        assert Enum.count(result.results) == @result_count
      end
    end

    @tag skip: "TODO: The currently deployed version does not return spec-conform SPARQL 1.1 TSV results, but just CSV with tabs as separators"
    test "TSV result via get" do
      use_cassette "dbpedia_select_as_tsv_via_get" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :tsv)
        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via post_url_encoded" do
      use_cassette "dbpedia_select_as_json_via_post_url_encoded" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :post,
              protocol_version: "1.0",
              result_format: :json)
        assert Enum.count(result.results) == @result_count
      end
    end

    @tag skip: "TODO: Why is this failing? Doesn't DBpedia/Virtuoso support this method? It seems there's a problem with that: https://www.mail-archive.com/virtuoso-users@lists.sourceforge.net/msg07984.html"
    test "JSON result via post_directly" do
      use_cassette "dbpedia_select_as_json_via_post_directly" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :post,
              protocol_version: "1.1",
              result_format: :json)

        assert Enum.count(result.results) == 3
      end
    end
  end

  describe "ASK query" do
    @test_ask_query """
      PREFIX : <http://dbpedia.org/resource/>
      PREFIX dbo: <http://dbpedia.org/ontology/>

      ASK WHERE { :Kevin_Bacon a dbo:Agent }
      """

    test "JSON result" do
      use_cassette "dbpedia_ask_as_json" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_ask_query, @dbpedia, result_format: :json)
        assert result.results == true
      end
    end

    test "XML result" do
      use_cassette "dbpedia_ask_as_xml" do
        assert {:ok, %Query.Result{} = result} =
          SPARQL.Client.query(@test_ask_query, @dbpedia, result_format: :xml)
        assert result.results == true
      end
    end
  end

  describe "DESCRIBE query" do
    @test_describe_query "DESCRIBE <http://dbpedia.org/resource/Elixir_(programming_language)>"

    test "default result format (Turtle)" do
      use_cassette "dbpedia_describe" do
        assert {:ok, %RDF.Graph{}} = SPARQL.Client.query(@test_describe_query, @dbpedia)
      end
    end

    test "N-Triples result" do
      use_cassette "dbpedia_describe_as_ntriples" do
        assert {:ok, %RDF.Graph{}} =
          SPARQL.Client.query(@test_describe_query, @dbpedia, result_format: :ntriples,
                                headers: %{"Accept" => "text/plain"})
      end
    end
  end

  describe "CONSTRUCT query" do
    @test_construct_query """
      CONSTRUCT { <http://example.org/Elixir> ?p ?o }
      WHERE  { <http://dbpedia.org/resource/Elixir_(programming_language)> ?p ?o }
      LIMIT 3
      """

    test "default result format (Turtle)" do
      use_cassette "dbpedia_construct" do
        assert {:ok, %RDF.Graph{} = graph} =
          SPARQL.Client.query(@test_construct_query, @dbpedia)
        assert RDF.Graph.triple_count(graph) == 3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)
      end
    end

    test "N-Triples result" do
      use_cassette "dbpedia_construct_as_ntriples" do
        assert {:ok, %RDF.Graph{} = graph} =
          SPARQL.Client.query(@test_construct_query, @dbpedia, result_format: :ntriples,
                                headers: %{"Accept" => "text/plain"})
        assert RDF.Graph.triple_count(graph) == 3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)

      end
    end
  end
end
