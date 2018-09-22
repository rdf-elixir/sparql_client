defmodule SPARQL.Client.Query.AskTest do
  use ExUnit.Case

  alias SPARQL.Query

  @example_endpoint "http://example.org/sparql"

  @default_accept_header SPARQL.Client.default_accept_header(:ask)

  @example_query "ASK WHERE { <http://example.org/Foo> a <http://example.org/Bar> }"
#  @example_query Query.new("ASK WHERE { <http://example.org/Foo> a <http://example.org/Bar> }").query_string |> IO.inspect(label: "@example_query")

  @json_result """
    {
      "head" : { } ,
      "boolean" : true
    }
    """

  @xml_result """
    <sparql xmlns="http://www.w3.org/2005/sparql-results#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.w3.org/2001/sw/DataAccess/rf1/result2.xsd">
      <boolean>true</boolean>
    </sparql>
    """

  @result @json_result |> Query.Result.JSON.decode() |> elem(1)


  setup do
    {:ok, body: URI.encode_query(%{query: Query.new(@example_query).query_string})}
  end

  test "JSON result", %{body: body} do
    Tesla.Mock.mock fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/sparql-results+json"
        %Tesla.Env{
              status: 200,
              body: @json_result,
              headers: [{"content-type", "application/sparql-results+json"}]
            }
    end

    assert SPARQL.Client.query(@example_query, @example_endpoint, result_format: :json) ==
            {:ok, @result}
  end

  test "XML result", %{body: body} do
    Tesla.Mock.mock fn
      env = %{method: :post, url: @example_endpoint, body: ^body} ->
        assert Tesla.get_header(env, "Accept") == "application/sparql-results+xml"
        %Tesla.Env{
              status: 200,
              body: @xml_result,
              headers: [{"content-type", "application/sparql-results+xml"}]
            }
    end

    assert SPARQL.Client.query(@example_query, @example_endpoint, result_format: :xml) ==
            {:ok, @result}
  end

  describe "content negotiation" do
    test "with default accept header and best accepted content-type returned (JSON)", %{body: body} do
      Tesla.Mock.mock fn
        env = %{method: :post, url: @example_endpoint, body: ^body} ->
          assert Tesla.get_header(env, "Accept") == @default_accept_header
          %Tesla.Env{
                status: 200,
                body: @json_result,
                headers: [{"content-type", Query.Result.JSON.media_type}]
              }
      end

      assert SPARQL.Client.query(@example_query, @example_endpoint) ==
              {:ok, @result}
    end
  end

  describe "unsupported content-type handling" do
    test "when no result_format set", %{body: body} do
      Tesla.Mock.mock fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
                status: 200,
                body: "bool\ntrue",
                headers: [{"content-type", "text/plain"}]
              }
      end

      assert SPARQL.Client.query(@example_query, @example_endpoint) ==
              {:error, ~s[unsupported result format for ask query: "text/plain"]}
    end

    test "when result_format set it's decoder is used", %{body: body} do
      Tesla.Mock.mock fn
        %{method: :post, url: @example_endpoint, body: ^body} ->
          %Tesla.Env{
                status: 200,
                body: @json_result,
                headers: [{"content-type", "text/plain"}]
              }
      end

      assert SPARQL.Client.query(@example_query, @example_endpoint, result_format: :json) ==
            {:ok, @result}
    end
  end

end
