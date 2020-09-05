defmodule SPARQL.Client.QueryTest do
  use ExUnit.Case

  alias SPARQL.Query

  @example_endpoint "http://example.org/sparql"

  @example_query "SELECT * WHERE { ?s ?p ?o }"

  @success_json_result """
  {
    "head": {
      "vars": [ "s" , "p" , "o" ]
    },
    "results": {
      "bindings": [
        {
          "s": { "type": "uri" , "value": "http://example.org/s1" } ,
          "p": { "type": "uri" , "value": "http://example.org/p1" } ,
          "o": { "type": "uri" , "value": "http://example.org/o1" }
        }
      ]
    }
  }
  """

  @success_result @success_json_result |> Query.Result.JSON.decode() |> elem(1)

  setup do
    {:ok, encoded_query: URI.encode_query(%{query: SPARQL.query(@example_query).query_string})}
  end

  describe "query request methods" do
    @success_response %Tesla.Env{
      status: 200,
      body: @success_json_result,
      headers: [{"content-type", Query.Result.JSON.media_type()}]
    }

    test "via GET", %{encoded_query: encoded_query} do
      url = @example_endpoint <> "?" <> encoded_query
      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1"
             ) ==
               {:ok, @success_result}
    end

    test "via URL-encoded POST", %{encoded_query: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.0"
             ) ==
               {:ok, @success_result}
    end

    test "via POST directly" do
      example_query = SPARQL.query(@example_query).query_string

      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^example_query} ->
          assert Tesla.get_header(env, "Content-Type") == "application/sparql-query"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.1"
             ) ==
               {:ok, @success_result}
    end

    test "default is via URL-encoded POST", %{encoded_query: body} do
      Tesla.Mock.mock(fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint) ==
               {:ok, @success_result}
    end

    test "custom headers via GET", %{encoded_query: body} do
      url = @example_endpoint <> "?" <> body

      Tesla.Mock.mock(fn
        env = %{method: :get, url: ^url} ->
          assert Tesla.get_header(env, "Authorization") == "Basic XXX=="
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               headers: %{"Authorization" => "Basic XXX=="}
             ) ==
               {:ok, @success_result}
    end

    test "custom headers via URL-encoded POST", %{encoded_query: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"
          assert Tesla.get_header(env, "Authorization") == "Basic XXX=="
          assert Tesla.get_header(env, "Accept") == "text/tab-separated-values"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.0",
               result_format: :tsv,
               headers: %{"Authorization" => "Basic XXX=="}
             ) ==
               {:ok, @success_result}
    end

    test "custom headers via POST directly" do
      example_query = SPARQL.query(@example_query).query_string

      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^example_query} ->
          assert Tesla.get_header(env, "Content-Type") == "application/sparql-query"
          assert Tesla.get_header(env, "Authorization") == "Basic XXX=="
          assert Tesla.get_header(env, "Accept") == "text/csv"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.1",
               result_format: :tsv,
               headers: %{
                 "Authorization" => "Basic XXX==",
                 "Accept" => "text/csv"
               }
             ) ==
               {:ok, @success_result}
    end

    test "invalid request forms" do
      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :unknown_method,
               protocol_version: "1.1"
             ) ==
               {:error,
                "unknown request method: :unknown_method with SPARQL protocol version 1.1"}

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.23"
             ) ==
               {:error, "unknown request method: :post with SPARQL protocol version 1.23"}

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.0"
             ) ==
               {:error, "unknown request method: :get with SPARQL protocol version 1.0"}
    end
  end

  describe "specifying an RDF Dataset" do
    @graph_uri "http://www.other.example/sparql/"
    @another_graph_uri "http://www.another.example/sparql/"

    @success_response %Tesla.Env{
      status: 200,
      body: @success_json_result,
      headers: [{"content-type", Query.Result.JSON.media_type()}]
    }

    test "one default graph via GET" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"query", SPARQL.query(@example_query).query_string},
            {"default-graph-uri", @graph_uri}
          ])

      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               default_graph: @graph_uri
             ) ==
               {:ok, @success_result}
    end

    test "multiple default graphs via GET" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"query", SPARQL.query(@example_query).query_string},
            {"default-graph-uri", @graph_uri},
            {"default-graph-uri", @another_graph_uri}
          ])

      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               default_graph: [@graph_uri, @another_graph_uri]
             ) ==
               {:ok, @success_result}
    end

    test "one named graph via GET" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"query", SPARQL.query(@example_query).query_string},
            {"named-graph-uri", @graph_uri}
          ])

      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               named_graph: @graph_uri
             ) ==
               {:ok, @success_result}
    end

    test "multiple named graphs via GET" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"query", SPARQL.query(@example_query).query_string},
            {"named-graph-uri", @graph_uri},
            {"named-graph-uri", @another_graph_uri}
          ])

      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               named_graph: [@graph_uri, @another_graph_uri]
             ) ==
               {:ok, @success_result}
    end

    test "multiple default and named graphs via GET" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"query", SPARQL.query(@example_query).query_string},
            {"default-graph-uri", @graph_uri <> "1"},
            {"named-graph-uri", @graph_uri <> "2"},
            {"named-graph-uri", @graph_uri <> "3"}
          ])

      Tesla.Mock.mock(fn %{method: :get, url: ^url} -> @success_response end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :get,
               protocol_version: "1.1",
               named_graph: [@graph_uri <> "2", @graph_uri <> "3"],
               default_graph: @graph_uri <> "1"
             ) ==
               {:ok, @success_result}
    end

    test "multiple default and named graphs via URL-encoded POST" do
      body =
        URI.encode_query([
          {"query", SPARQL.query(@example_query).query_string},
          {"default-graph-uri", @graph_uri <> "1"},
          {"named-graph-uri", @graph_uri <> "2"},
          {"named-graph-uri", @graph_uri <> "3"}
        ])

      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.0",
               named_graph: [@graph_uri <> "2", @graph_uri <> "3"],
               default_graph: @graph_uri <> "1"
             ) ==
               {:ok, @success_result}
    end

    test "multiple default and named graphs via POST directly" do
      url =
        @example_endpoint <>
          "?" <>
          URI.encode_query([
            {"default-graph-uri", @graph_uri <> "1"},
            {"named-graph-uri", @graph_uri <> "2"},
            {"named-graph-uri", @graph_uri <> "3"}
          ])

      example_query = SPARQL.query(@example_query).query_string

      Tesla.Mock.mock(fn
        env = %{method: :post, url: ^url, body: ^example_query} ->
          assert Tesla.get_header(env, "Content-Type") == "application/sparql-query"
          @success_response
      end)

      assert SPARQL.Client.query(@example_query, @example_endpoint,
               request_method: :post,
               protocol_version: "1.1",
               named_graph: [@graph_uri <> "2", @graph_uri <> "3"],
               default_graph: @graph_uri <> "1"
             ) ==
               {:ok, @success_result}
    end
  end

  describe "error handling" do
    test "malformed query" do
      assert {:error, _} = SPARQL.Client.query("Foo bar", @example_endpoint)
    end

    test "4XX response" do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 400, body: "error"} end)

      assert SPARQL.Client.query(@example_query, @example_endpoint) ==
               {:error, %Tesla.Env{status: 400, body: "error"}}
    end

    test "5XX response" do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 500, body: "error"} end)

      assert SPARQL.Client.query(@example_query, @example_endpoint) ==
               {:error, %Tesla.Env{status: 500, body: "error"}}
    end
  end
end
