defmodule SPARQL.Client.Query.DescribeTest do
  use SPARQL.Client.Test.Case

  @example_endpoint "http://example.org/sparql"

  @default_accept_header SPARQL.Client.Query.default_accept_header(:describe)

  @example_query "DESCRIBE <http://example.org/S>"

  @result_graph RDF.Graph.new(
                  {~I<http://example.org/S>, ~I<http://example.org/p>, ~I<http://example.org/O>}
                )
  @result_dataset RDF.Dataset.new(@result_graph)
  @turtle_result RDF.Turtle.write_string!(@result_graph)
  @ntriples_result RDF.NTriples.write_string!(@result_graph)
  @json_ld_result JSON.LD.write_string!(@result_dataset)

  setup do
    {:ok, body: URI.encode_query(%{query: SPARQL.query(@example_query).query_string})}
  end

  test "Turtle result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "text/turtle"

        %Tesla.Env{
          status: 200,
          body: @turtle_result,
          headers: [{"content-type", "text/turtle"}]
        }
    end)

    assert_equal_graph(
      @result_graph,
      SPARQL.Client.describe(@example_query, @example_endpoint, result_format: :turtle)
    )
  end

  test "JSON-LD result", %{body: body} do
    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/ld+json"

        %Tesla.Env{
          status: 200,
          body: @json_ld_result,
          headers: [{"content-type", "application/ld+json"}]
        }
    end)

    assert SPARQL.Client.describe(@example_query, @example_endpoint, result_format: :jsonld) ==
             {:ok, @result_dataset}
  end

  test "NTriples result" do
    url =
      @example_endpoint <>
        "?" <> URI.encode_query(%{query: SPARQL.query(@example_query).query_string})

    Tesla.Mock.mock(fn
      env = %{method: :get, url: ^url} ->
        assert Tesla.get_header(env, "Accept") == "application/n-triples"

        %Tesla.Env{
          status: 200,
          body: @ntriples_result,
          headers: [{"content-type", "application/n-triples"}]
        }
    end)

    assert_equal_graph(
      @result_graph,
      SPARQL.Client.describe(@example_query, @example_endpoint,
        result_format: :ntriples,
        request_method: :get,
        protocol_version: "1.1"
      )
    )
  end

  test "NQuads result" do
    example_query = SPARQL.query(@example_query).query_string

    Tesla.Mock.mock(fn
      env = %{method: :post, url: @example_endpoint, body: ^example_query} ->
        assert Tesla.get_header(env, "Accept") == "application/n-quads"

        %Tesla.Env{
          status: 200,
          body: RDF.NQuads.write_string!(@result_graph),
          headers: [{"content-type", "application/n-quads"}]
        }
    end)

    assert SPARQL.Client.describe(@example_query, @example_endpoint,
             result_format: :nquads,
             request_method: :post,
             protocol_version: "1.1"
           ) ==
             {:ok, @result_dataset}
  end

  describe "content negotiation" do
    test "with default accept header and best accepted content-type returned (Turtle)", %{
      body: body
    } do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == @default_accept_header

          %Tesla.Env{
            status: 200,
            body: @turtle_result,
            headers: [{"content-type", "text/turtle"}]
          }
      end)

      assert_equal_graph(
        @result_graph,
        SPARQL.Client.describe(@example_query, @example_endpoint)
      )
    end

    test "unsupported content-type response and no result_format set", %{body: body} do
      Tesla.Mock.mock(fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
            status: 200,
            body: "bool\ntrue",
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert SPARQL.Client.describe(@example_query, @example_endpoint) ==
               {:error,
                "SPARQL service responded with text/plain content which can't be interpreted. Try specifying one of the supported result formats with the :result_format option."}
    end
  end

  describe "unsupported content-type handling" do
    test "when result_format set it's decoder is used", %{body: body} do
      Tesla.Mock.mock(fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
            status: 200,
            body: @turtle_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert_equal_graph(
        @result_graph,
        SPARQL.Client.describe(@example_query, @example_endpoint, result_format: :turtle)
      )
    end
  end

  describe "custom accept header" do
    test "with valid format", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/turtle"

          %Tesla.Env{
            status: 200,
            body: @turtle_result,
            headers: [{"content-type", "text/turtle"}]
          }
      end)

      assert_equal_graph(
        @result_graph,
        SPARQL.Client.describe(@example_query, @example_endpoint,
          headers: %{"Accept" => "text/turtle"}
        )
      )
    end

    test "with invalid format and no result_format", %{body: body} do
      Tesla.Mock.mock(fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == "text/plain"

          %Tesla.Env{
            status: 200,
            body: @ntriples_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert SPARQL.Client.describe(@example_query, @example_endpoint,
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
            body: @ntriples_result,
            headers: [{"content-type", "text/plain"}]
          }
      end)

      assert_equal_graph(
        @result_graph,
        SPARQL.Client.describe(@example_query, @example_endpoint,
          result_format: :ntriples,
          headers: %{"Accept" => "text/plain"}
        )
      )
    end
  end
end
