defmodule SPARQL.Client.Mixfile do
  use Mix.Project

  @repo_url "https://github.com/marcelotto/sparql-client"

  @version File.read!("VERSION") |> String.trim


  def project do
    [
      app: :sparql_client,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "SPARQL.Client",
      docs: [
        main: "SPARQL.Client",
        source_url: @repo_url,
        source_ref: "v#{@version}",
        extras: ["README.md"],
      ],

      # ExVCR
      preferred_cli_env: [
        vcr: :dev, "vcr.delete": :dev, "vcr.check": :dev, "vcr.show": :dev
      ],
    ]
  end

  defp description do
    """
    A SPARQL protocol client for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url},
      files: ~w[lib mix.exs README.md CHANGELOG.md LICENSE.md VERSION]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:sparql, path: "../sparql"},

      {:tesla, "~> 0.10"},
      {:hackney, "~> 1.10"},
      {:content_type, "~> 0.1"},

      # Development
      {:dialyxir, "~> 0.5",  only: [:dev, :test], runtime: false},
      {:credo, "~> 0.8",     only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.8",     only: [:dev, :test]},
      {:ex_doc, "~> 0.17.1", only: :dev, runtime: false},
      {:inch_ex, ">= 0.0.0", only: [:dev, :test]}
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
