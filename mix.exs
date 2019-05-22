defmodule SPARQL.Client.Mixfile do
  use Mix.Project

  @repo_url "https://github.com/marcelotto/sparql_client"

  @version File.read!("VERSION") |> String.trim


  def project do
    [
      app: :sparql_client,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "SPARQL.Client",
      docs: [
        main: "SPARQL.Client",
        source_url: @repo_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"],
      ],

      # ExVCR
      preferred_cli_env: [
        vcr: :dev, "vcr.delete": :dev, "vcr.check": :dev, "vcr.show": :dev
      ],

      # ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
    ]
  end

  defp description do
    """
    A SPARQL client for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{
        "Homepage" => "https://rdf-elixir.dev",
        "GitHub" => @repo_url,
        "Changelog" => @repo_url <> "/blob/master/CHANGELOG.md",
      },
      files: ~w[lib mix.exs README.md CHANGELOG.md LICENSE.md VERSION]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:sparql, "~> 0.3"},
      {:rdf, "~> 0.6"},
      {:json_ld, "~> 0.3"},

      {:tesla, "~> 1.2"},
      {:content_type, "~> 0.1"},

      # Development
      {:hackney, "~> 1.15",     only: [:dev, :test]},
      {:dialyxir, "~> 0.5",     only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0",        only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.10",       only: [:dev, :test]},
      {:ex_doc, "~> 0.20",      only: :dev, runtime: false},
      {:excoveralls, "~> 0.11", only: :test},
    ]
  end

  defp aliases do
    [
      integration_test: &integration_test/1
    ]
  end

  defp integration_test(_) do
    System.put_env "MIX_ENV", "dev"
    Mix.Task.run :test, ["integration_test"]
  end
end
