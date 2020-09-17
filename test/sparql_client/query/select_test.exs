defmodule SPARQL.Client.Query.SelectTest do
  use ExUnit.Case

  alias SPARQL.Query
  import RDF.Sigils

  @example_endpoint "http://example.org/sparql"

  @default_accept_header SPARQL.Client.Query.default_accept_header(:select)

  @example_query "SELECT * WHERE { ?s ?p ?o }"

  @json_result """
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

  @xml_result """
  <sparql xmlns="http://www.w3.org/2005/sparql-results#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.w3.org/2001/sw/DataAccess/rf1/result2.xsd">
    <head>
      <variable name="s"/>
      <variable name="p"/>
      <variable name="o"/>
    </head>
    <results>
      <result>
        <binding name="s">
          <uri>http://example.org/s1</uri>
        </binding>
        <binding name="p">
          <uri>http://example.org/p1</uri>
        </binding>
        <binding name="o">
          <uri>http://example.org/o1</uri>
        </binding>
      </result>
    </results>
  </sparql>
  """

  @tsv_result """
  ?s	?p	?o
  <http://example.org/s1>	<http://example.org/p1>	<http://example.org/o1>
  """

  @csv_result """
  s,p,o
  http://example.org/s1,http://example.org/p1,http://example.org/o1
  """

  @result @json_result |> Query.Result.JSON.decode() |> elem(1)

  setup do
    {:ok, body: URI.encode_query(%{query: SPARQL.query(@example_query).query_string})}
  end

  test "JSON result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/sparql-results+json"

        %Tesla.Env{
          status: 200,
          body: @json_result,
          headers: [{"content-type", "application/sparql-results+json"}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :json) ==
             {:ok, @result}
  end

  test "XML result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/sparql-results+xml"

        %Tesla.Env{
          status: 200,
          body: @xml_result,
          headers: [{"content-type", "application/sparql-results+xml"}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :xml) ==
             {:ok, @result}
  end

  test "TSV result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "text/tab-separated-values"

        %Tesla.Env{
          status: 200,
          body: @tsv_result,
          headers: [{"content-type", "text/tab-separated-values"}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :tsv) ==
             {:ok, @result}
  end

  test "CSV result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "text/csv"

        %Tesla.Env{
          status: 200,
          body: @csv_result,
          headers: [{"content-type", "text/csv"}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :csv) ==
             Query.Result.CSV.decode(@csv_result)
  end

  test "international characters in response body", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/sparql-results+json"

        %Tesla.Env{
          status: 200,
          body: """
          {
            "results": {
              "bindings": [
                {
                  "name": { "type": "literal" , "xml:lang": "jp", "value": "東京" }
                }
              ]
            }
          }
          """,
          headers: [{"content-type", "application/sparql-results+json"}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :json) ==
             {:ok, %Query.Result{results: [%{"name" => ~L"東京"jp}]}}
  end

  describe "content negotiation" do
    test "with default accept header and best accepted content-type returned (JSON)", %{
      body: body
    } do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == @default_accept_header

          %Tesla.Env{
            status: 200,
            body: @json_result,
            headers: [{"content-type", Query.Result.JSON.media_type()}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint) ==
               {:ok, @result}
    end

    test "with default accept header and worst accepted content-type returned (CSV)", %{
      body: body
    } do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == @default_accept_header

          %Tesla.Env{
            status: 200,
            body: @csv_result,
            headers: [{"content-type", Query.Result.CSV.media_type()}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint) ==
               Query.Result.CSV.decode(@csv_result)
    end

    test "different content-type than the accepted", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/tab-separated-values"

          %Tesla.Env{
            status: 200,
            body: @json_result,
            headers: [{"content-type", "application/sparql-results+json"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :tsv) ==
               {:ok, @result}
    end
  end

  describe "unsupported content-type handling" do
    test "when no result_format set", %{body: body} do
      Tesla.Mock.mock(fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
            status: 200,
            body: "<html><body>HTML content</body></html>",
            headers: [{"content-type", "text/html"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint) ==
               {:error,
                "SPARQL service responded with text/html content which can't be interpreted. Try specifying one of the supported result formats with the :result_format option."}
    end

    test "when result_format set it's decoder is used", %{body: body} do
      Tesla.Mock.mock(fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
            status: 200,
            body: @tsv_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint, result_format: :tsv) ==
               {:ok, @result}
    end
  end

  describe "custom accept header" do
    test "with valid format", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/tab-separated-values"

          %Tesla.Env{
            status: 200,
            body: @tsv_result,
            headers: [{"content-type", "text/tab-separated-values"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint,
               headers: %{"Accept" => "text/tab-separated-values"}
             ) ==
               {:ok, @result}
    end

    test "with invalid format and no result_format", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/plain"

          %Tesla.Env{
            status: 200,
            body: @tsv_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint,
               headers: %{"Accept" => "text/plain"}
             ) ==
               {:error,
                "SPARQL service responded with text/plain content which can't be interpreted. Try specifying one of the supported result formats with the :result_format option."}
    end

    test "with invalid format and result_format", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/plain"

          %Tesla.Env{
            status: 200,
            body: @json_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert SPARQL.Client.select(@example_query, @example_endpoint,
               result_format: :json,
               headers: %{"Accept" => "text/plain"}
             ) ==
               {:ok, @result}
    end
  end

  test "when called with another type of query" do
    assert_raise RuntimeError, "expected a SELECT query, got: DESCRIBE query", fn ->
      SPARQL.Client.select("DESCRIBE <http://example.org/S>", @example_endpoint)
    end
  end

  test "raw mode" do
    body = URI.encode_query(%{query: @example_query})

    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == @default_accept_header

        %Tesla.Env{
          status: 200,
          body: @json_result,
          headers: [{"content-type", Query.Result.JSON.media_type()}]
        }
    end)

    assert SPARQL.Client.select(@example_query, @example_endpoint, raw_mode: true) ==
             {:ok, @result}
  end
end
