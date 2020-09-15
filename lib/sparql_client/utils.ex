defmodule SPARQL.Client.Utils do
  @moduledoc false

  def map_while_ok(enum, fun) do
    with {:ok, mapped} <-
           Enum.reduce_while(enum, {:ok, []}, fn e, {:ok, acc} ->
             with {:ok, value} <- fun.(e) do
               {:cont, {:ok, [value | acc]}}
             else
               error -> {:halt, error}
             end
           end) do
      {:ok, Enum.reverse(mapped)}
    end
  end

  def map_join_while_ok(enum, joiner \\ "", fun) do
    with {:ok, mapped} <- map_while_ok(enum, fun) do
      {:ok, Enum.join(mapped, joiner)}
    end
  end
end
