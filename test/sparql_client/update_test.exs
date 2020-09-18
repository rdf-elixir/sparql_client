defmodule SPARQL.Client.UpdateTest do
  use SPARQL.Client.Test.Case

  alias SPARQL.Client.Update

  @example_endpoint "http://example.com/sparql"

  @example_description EX.Foo |> EX.bar(EX.Baz)
  @example_graph RDF.Graph.new(@example_description, prefixes: %{ex: EX})
                 |> RDF.Graph.add(EX.Other |> EX.p("string"))
  @example_dataset RDF.Dataset.new(@example_description)
                   |> RDF.Dataset.add({EX.Other, EX.p(), "string", EX.NamedGraph})

  describe "insert_data/3" do
    test "direct POST" do
      mock_update_request(:direct, :insert_data, @example_description)
      assert SPARQL.Client.insert_data(@example_description, @example_endpoint) == :ok

      mock_update_request(:direct, :insert_data, @example_graph)
      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint) == :ok

      mock_update_request(:direct, :insert_data, @example_dataset)
      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint) == :ok
    end

    test "URL-encoded POST" do
      mock_update_request(:url_encoded, :insert_data, @example_description)

      assert SPARQL.Client.insert_data(@example_description, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :insert_data, @example_graph)

      assert SPARQL.Client.insert_data(@example_graph, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :insert_data, @example_dataset)

      assert SPARQL.Client.insert_data(@example_dataset, @example_endpoint,
               request_method: :url_encoded
             ) == :ok
    end

    test "with passing an update string directly in raw-mode" do
      {:ok, update} = Update.Builder.update_data(:insert_data, @example_graph)
      mock_update_request(:direct, :insert_data, @example_graph)
      assert SPARQL.Client.insert_data(update, @example_endpoint, raw_mode: true) == :ok

      {:ok, update} = Update.Builder.update_data(:insert_data, @example_dataset)

      mock_update_request(:url_encoded, :insert_data, @example_dataset)

      assert SPARQL.Client.insert_data(update, @example_endpoint,
               request_method: :url_encoded,
               raw_mode: true
             ) ==
               :ok
    end
  end

  describe "delete_data/3" do
    test "direct POST" do
      mock_update_request(:direct, :delete_data, @example_description)
      assert SPARQL.Client.delete_data(@example_description, @example_endpoint) == :ok

      mock_update_request(:direct, :delete_data, @example_graph)
      assert SPARQL.Client.delete_data(@example_graph, @example_endpoint) == :ok

      mock_update_request(:direct, :delete_data, @example_dataset)
      assert SPARQL.Client.delete_data(@example_dataset, @example_endpoint) == :ok
    end

    test "URL-encoded POST" do
      mock_update_request(:url_encoded, :delete_data, @example_description)

      assert SPARQL.Client.delete_data(@example_description, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :delete_data, @example_graph)

      assert SPARQL.Client.delete_data(@example_graph, @example_endpoint,
               request_method: :url_encoded
             ) == :ok

      mock_update_request(:url_encoded, :delete_data, @example_dataset)

      assert SPARQL.Client.delete_data(@example_dataset, @example_endpoint,
               request_method: :url_encoded
             ) == :ok
    end

    test "with passing an update string directly in raw-mode" do
      {:ok, update} = Update.Builder.update_data(:delete_data, @example_graph)
      mock_update_request(:direct, :delete_data, @example_graph)
      assert SPARQL.Client.delete_data(update, @example_endpoint, raw_mode: true) == :ok

      {:ok, update} = Update.Builder.update_data(:delete_data, @example_description)

      mock_update_request(:url_encoded, :delete_data, @example_description)

      assert SPARQL.Client.delete_data(update, @example_endpoint,
               request_method: :url_encoded,
               raw_mode: true
             ) ==
               :ok
    end
  end

  def mock_update_request(request_method, update_form, data, opts \\ [])

  def mock_update_request(:direct, update_form, data, opts) do
    {:ok, update} = Update.Builder.update_data(update_form, data, opts)
    endpoint = Keyword.get(opts, :endpoint, @example_endpoint)

    Tesla.Mock.mock(fn
      env = %{method: :post, url: ^endpoint, body: ^update} ->
        assert Tesla.get_header(env, "Content-Type") == "application/sparql-update"

        %Tesla.Env{
          status: Keyword.get(opts, :status, 204),
          body: Keyword.get(opts, :response, "")
        }
    end)
  end

  def mock_update_request(:url_encoded, update_form, data, opts) do
    {:ok, update} = Update.Builder.update_data(update_form, data, opts)
    update_query_param = URI.encode_query(%{update: update})
    endpoint = Keyword.get(opts, :endpoint, @example_endpoint)

    Tesla.Mock.mock(fn
      env = %{method: :post, url: ^endpoint, body: ^update_query_param} ->
        assert Tesla.get_header(env, "Content-Type") == "application/x-www-form-urlencoded"

        %Tesla.Env{
          status: Keyword.get(opts, :status, 204),
          body: Keyword.get(opts, :response, "")
        }
    end)
  end
end
