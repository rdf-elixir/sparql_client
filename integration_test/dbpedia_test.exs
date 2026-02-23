# Issues with the DBpedia SPARQL endpoint (Virtuoso):
#
# - The endpoint requires HTTPS (http:// redirects to https:// via 303)
# - Virtuoso's content negotiation is unreliable with */*;q=0.1 in Accept headers;
#   some backends behind the load balancer return HTML instead of query results,
#   so we use GET and explicit result formats where needed
# - POST requests with Content-Type: application/sparql-query hang indefinitely
#   (https://github.com/openlink/virtuoso-opensource/issues/842)
# - POST requests may require increased recv_timeout (Hackney default is too low)
# - The Turtle results are rather crappy since it almost always is invalid, like
#   rdf:langString literals without a language tag, invalid characters in prefixed names etc.

defmodule SPARQL.Client.DBpediaTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest SPARQL.Client

  alias SPARQL.Query
  import RDF.Sigils

  @dbpedia "https://dbpedia.org/sparql"
  @request_opts [adapter: [recv_timeout: 30_000]]

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

    test "SELECT query with default result format via get" do
      use_cassette "dbpedia_select_via_defaults" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via get" do
      use_cassette "dbpedia_select_as_json_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :json,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "XML result via get" do
      use_cassette "dbpedia_select_as_xml_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :xml,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "CSV result via get" do
      use_cassette "dbpedia_select_as_csv_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :csv,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "TSV result via get" do
      use_cassette "dbpedia_select_as_tsv_via_get" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :tsv,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via post_url_encoded" do
      use_cassette "dbpedia_select_as_json_via_post_url_encoded" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :post,
                   protocol_version: "1.0",
                   result_format: :json,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == @result_count
      end
    end

    test "JSON result via post_directly" do
      use_cassette "dbpedia_select_as_json_via_post_directly" do
        assert {:ok, %Query.Result{} = result} =
                 SPARQL.Client.query(@test_select_query, @dbpedia,
                   request_method: :post,
                   protocol_version: "1.1",
                   result_format: :json,
                   request_opts: @request_opts
                 )

        assert Enum.count(result.results) == 3
      end
    end
  end

  describe "ASK query" do
    @test_ask_query """
    PREFIX : <http://dbpedia.org/resource/>
    PREFIX dbo: <http://dbpedia.org/ontology/>

    ASK WHERE { :Kevin_Bacon a dbo:Person }
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
        assert {:ok, %RDF.Graph{}} =
                 SPARQL.Client.query(@test_describe_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1"
                 )
      end
    end

    test "N-Triples result" do
      use_cassette "dbpedia_describe_as_ntriples" do
        assert {:ok, %RDF.Graph{}} =
                 SPARQL.Client.query(@test_describe_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :ntriples,
                   headers: %{"Accept" => "text/plain"}
                 )
      end
    end
  end

  describe "CONSTRUCT query" do
    @test_construct_query """
    CONSTRUCT { <http://example.org/Elixir> ?p ?o }
    WHERE  { <http://dbpedia.org/resource/Elixir_(programming_language)> ?p ?o }
    LIMIT 3
    """

    # DBpedia has duplicate triples, so LIMIT 3 may yield fewer distinct triples after
    # deduplication in the RDF.Graph (e.g. rdf:type dbo:Language appears multiple times)
    test "default result format (Turtle)" do
      use_cassette "dbpedia_construct" do
        assert {:ok, %RDF.Graph{} = graph} =
                 SPARQL.Client.query(@test_construct_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1"
                 )

        assert RDF.Graph.triple_count(graph) in 2..3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)
      end
    end

    test "N-Triples result" do
      use_cassette "dbpedia_construct_as_ntriples" do
        assert {:ok, %RDF.Graph{} = graph} =
                 SPARQL.Client.query(@test_construct_query, @dbpedia,
                   request_method: :get,
                   protocol_version: "1.1",
                   result_format: :ntriples,
                   headers: %{"Accept" => "text/plain"}
                 )

        assert RDF.Graph.triple_count(graph) in 2..3
        assert RDF.Graph.describes?(graph, ~I<http://example.org/Elixir>)
      end
    end
  end
end
