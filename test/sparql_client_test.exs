defmodule SPARQL.ClientTest do
  use SPARQL.Client.Test.Case

  doctest SPARQL.Client

  alias SPARQL.Query

  import ExUnit.CaptureLog

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

  @success_response %Tesla.Env{
    status: 200,
    body: @success_json_result,
    headers: [{"content-type", Query.Result.JSON.media_type()}]
  }

  test "max_redirects option" do
    Tesla.Mock.mock(fn
      env ->
        assert {Tesla.Middleware.FollowRedirects, :call, [[max_redirects: 42]]} in env.__client__.pre

        @success_response
    end)

    SPARQL.Client.query(@example_query, @example_endpoint, max_redirects: 42)
  end

  test "logger option" do
    Tesla.Mock.mock(fn _env -> @success_response end)

    log =
      capture_log(fn ->
        SPARQL.Client.query(@example_query, @example_endpoint, logger: true, max_redirects: 2)
      end)

    assert log =~ ">>> REQUEST >>>"
    assert log =~ "<<< RESPONSE <<<"
  end
end
