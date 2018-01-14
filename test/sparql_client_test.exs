defmodule SPARQL.ClientTest do
  use ExUnit.Case
  doctest SPARQL.Client

  test "greets the world" do
    assert SPARQL.Client.hello() == :world
  end
end
