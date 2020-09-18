defmodule SPARQL.Client.ConfigTest do
  use SPARQL.Client.Test.Case

  @example_endpoint "http://example.com/sparql"
  @example_data EX.S |> EX.p(EX.O)

  @original_config Application.get_all_env(:sparql_client)

  setup %{config: config} do
    Application.put_all_env(sparql_client: config)

    on_exit(&reset_config/0)

    {:ok, config}
  end

  @tag config: [http_headers: %{"Authorization" => "Basic YWxhZGRpbjpvcGVuc2VzYW1l"}]
  test "http_headers with map" do
    Tesla.Mock.mock(fn env ->
      assert Tesla.get_header(env, "Authorization") == "Basic YWxhZGRpbjpvcGVuc2VzYW1l"
      assert Tesla.get_header(env, "Content-Type")

      %Tesla.Env{status: 200}
    end)

    assert SPARQL.Client.insert_data(@example_data, @example_endpoint) == :ok
  end

  @tag config: [http_headers: &HeaderConfigTestMod.http_header_test_function/2]
  test "http_headers with function" do
    Tesla.Mock.mock(fn env ->
      assert Tesla.get_header(env, "Authorization") == "Basic YWxhZGRpbjpvcGVuc2VzYW1l"
      assert Tesla.get_header(env, "Content-Type") == "application/sparql-update;foo"

      %Tesla.Env{status: 200}
    end)

    assert SPARQL.Client.insert_data(@example_data, @example_endpoint) == :ok
  end

  def reset_config do
    Application.get_all_env(:sparql_client)
    |> Enum.each(fn {key, _} -> Application.delete_env(:sparql_client, key) end)

    Application.put_all_env(sparql_client: @original_config)
  end
end
