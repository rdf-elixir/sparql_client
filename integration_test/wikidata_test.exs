# Wikidata SPARQL endpoint (Blazegraph) notes:
#
# - Requires a User-Agent header (requests without one may be rejected)

defmodule SPARQL.Client.WikidataTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias SPARQL.Query
  import RDF.Sigils

  @wikidata "https://query.wikidata.org/sparql"
  @headers %{"User-Agent" => "SPARQL.Client Integration Tests"}

  describe "SELECT query" do
    @result_count 3

    @test_select_query """
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>

    SELECT ?item ?label
    WHERE {
      ?item wdt:P31 wd:Q9143 ;
            rdfs:label ?label .
      FILTER(LANG(?label) = "en")
    }
    ORDER BY ?label
    LIMIT #{@result_count}
    """

    test "SELECT query with defaults" do
      use_cassette "wikidata_select_via_defaults" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata, headers: @headers)

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via get" do
      use_cassette "wikidata_select_as_json_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :json,
                   headers: @headers
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "CSV result via get" do
      use_cassette "wikidata_select_as_csv_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :csv,
                   headers: @headers
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via post_url_encoded" do
      use_cassette "wikidata_select_as_json_via_post_url_encoded" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata,
                   request_method: :post,
                   protocol_version: "1.0",
                   result_format: :json,
                   headers: @headers
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via post_directly" do
      use_cassette "wikidata_select_as_json_via_post_directly" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata,
                   request_method: :post,
                   protocol_version: "1.1",
                   result_format: :json,
                   headers: @headers
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "XML result" do
      use_cassette "wikidata_select_as_xml" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @wikidata,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :xml,
                   headers: @headers
                 )

        assert Enum.count(result.results) == @result_count
      end
    end
  end

  describe "ASK query" do
    # Is Douglas Adams (Q42) a human (Q5)?
    @test_ask_query """
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>

    ASK WHERE { wd:Q42 wdt:P31 wd:Q5 }
    """

    test "JSON result" do
      use_cassette "wikidata_ask_as_json" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_ask_query, @wikidata,
                   result_format: :json,
                   headers: @headers
                 )

        assert result.results == true
      end
    end

    test "XML result" do
      use_cassette "wikidata_ask_as_xml" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_ask_query, @wikidata,
                   result_format: :xml,
                   headers: @headers
                 )

        assert result.results == true
      end
    end
  end

  describe "CONSTRUCT query" do
    @test_construct_query """
    PREFIX wd: <http://www.wikidata.org/entity/>

    CONSTRUCT { <http://example.org/Elixir> ?p ?o }
    WHERE { wd:Q5362035 ?p ?o }
    LIMIT 3
    """

    test "N-Triples result" do
      use_cassette "wikidata_construct_as_ntriples" do
        assert {:ok, %RDF.Graph{} = graph} =
                 SPARQL.Client.query(@test_construct_query, @wikidata,
                   result_format: :ntriples,
                   headers: @headers
                 )

        assert RDF.Graph.triple_count(graph) == 3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)
      end
    end

    test "Turtle result" do
      use_cassette "wikidata_construct_as_turtle" do
        assert {:ok, %RDF.Graph{} = graph} =
                 SPARQL.Client.query(@test_construct_query, @wikidata,
                   result_format: :turtle,
                   headers: @headers
                 )

        assert RDF.Graph.triple_count(graph) == 3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)
      end
    end
  end

  describe "DESCRIBE query" do
    @test_describe_query "DESCRIBE <http://www.wikidata.org/entity/Q5362035>"

    test "N-Triples result" do
      use_cassette "wikidata_describe_as_ntriples" do
        assert {:ok, %RDF.Graph{}} =
                 SPARQL.Client.query(@test_describe_query, @wikidata,
                   result_format: :ntriples,
                   headers: @headers
                 )
      end
    end
  end
end
