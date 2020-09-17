defmodule HeaderConfigTestMod do
  def http_header_test_function(%SPARQL.Client.Request{}, headers) do
    content_type = headers["Content-Type"]

    %{
      "Content-Type" => content_type <> ";foo",
      "Authorization" => "Basic YWxhZGRpbjpvcGVuc2VzYW1l"
    }
  end
end
