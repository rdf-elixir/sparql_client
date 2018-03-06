defmodule SPARQL.Client.DBpediaTest do
  use ExUnit.Case # In case test behaves unstable: , async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest SPARQL.Client

  alias SPARQL.Query

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
        ?person dbo:birthPlace :Berlin .
        ?person dbo:birthDate  ?birth .
        ?person foaf:name      ?name .
        ?person dbo:deathDate  ?death .
        FILTER (?birth < "1900-01-01"^^xsd:date) .
      }
      ORDER BY ?name
      LIMIT #{@result_count}
      """

    test "SELECT query with defaults" do
      use_cassette "dbpedia_select_via_defaults" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    test "SELECT query as JSON result via get" do
      use_cassette "dbpedia_select_as_json_via_get" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :json)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    test "SELECT query as XML result via get" do
      use_cassette "dbpedia_select_as_xml_via_get" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :xml)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    test "SELECT query as CSV result via get" do
      use_cassette "dbpedia_select_as_csv_via_get" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :csv)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    @tag skip: "TODO: The currently deployed version does not return spec-conform SPARQL 1.1 TSV results, but just CSV with tabs as separators"
    test "SELECT query as TSV result via get" do
      use_cassette "dbpedia_select_as_tsv_via_get" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :get,
              protocol_version: "1.1",
              result_format: :tsv)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    test "SELECT query as JSON result via post_url_encoded" do
      use_cassette "dbpedia_select_as_json_via_post_url_encoded" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :post,
              protocol_version: "1.0",
              result_format: :json)
        assert Enum.count(result_set.results) == @result_count
      end
    end

    @tag skip: "TODO: Why is this failing? Doesn't DBpedia/Virtuoso support this method? It seems there's a problem with that: https://www.mail-archive.com/virtuoso-users@lists.sourceforge.net/msg07984.html"
    test "SELECT query as JSON result via post_directly" do
      use_cassette "dbpedia_select_as_json_via_post_directly" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_select_query, @dbpedia,
              request_method: :post,
              protocol_version: "1.1",
              result_format: :json)

        assert Enum.count(result_set.results) == 3
      end
    end
  end

  describe "ASK query" do
    @test_ask_query """
      PREFIX : <http://dbpedia.org/resource/>
      PREFIX dbo: <http://dbpedia.org/ontology/>

      ASK WHERE { :Kevin_Bacon a dbo:Agent }
      """

    test "ASK query as JSON" do
      use_cassette "dbpedia_ask_as_json" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_ask_query, @dbpedia, result_format: :json)
        assert result_set.results == true
      end
    end

    test "ASK query as XML" do
      use_cassette "dbpedia_ask_as_xml" do
        assert {:ok, %Query.ResultSet{} = result_set} =
          SPARQL.Client.query(@test_ask_query, @dbpedia, result_format: :xml)
        assert result_set.results == true
      end
    end
  end

end
