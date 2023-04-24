defmodule SPARQL.Client.Mixfile do
  use Mix.Project

  @repo_url "https://github.com/rdf-elixir/sparql_client"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :sparql_client,
      version: @version,
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
        extras: ["CHANGELOG.md"]
      ],
      preferred_cli_env: [
        check: :test
      ],

      # ExVCR
      preferred_cli_env: [
        vcr: :dev,
        "vcr.delete": :dev,
        "vcr.check": :dev,
        "vcr.show": :dev
      ],

      # ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
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
        "Changelog" => @repo_url <> "/blob/master/CHANGELOG.md"
      },
      files: ~w[lib mix.exs README.md CHANGELOG.md LICENSE.md VERSION]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      rdf_ex_dep(:rdf, "~> 1.0"),
      rdf_ex_dep(:sparql, ">= 0.3.8"),
      rdf_ex_dep(:json_ld, ">= 0.3.6"),
      rdf_ex_dep(:rdf_xml, "~> 1.0"),
      {:tesla, "~> 1.2"},
      {:content_type, "~> 0.1"},
      {:nimble_options, "~> 0.3 or ~> 1.0"},

      # Development
      # We now have Hackney as a hard dependency through JSON-LD.ex; we should
      # re-enable this once we got rid of this hard-dependency
      # {:hackney, "~> 1.15", only: [:dev, :test]},
      {:gun, "~> 1.3", only: [:dev, :test]},
      {:mint, "~> 1.2", only: [:dev, :test]},
      {:castore, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.13", only: [:dev, :test]},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15", only: :test}
    ]
  end

  defp rdf_ex_dep(dep, version) do
    case System.get_env("RDF_EX_PACKAGES_SRC") do
      "LOCAL" -> {dep, path: "../#{dep}"}
      _ -> {dep, version}
    end
  end

  defp aliases do
    [
      integration_test: &integration_test/1,
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "test --warnings-as-errors",
        "credo"
      ]
    ]
  end

  defp integration_test(_) do
    System.put_env("MIX_ENV", "dev")
    Mix.Task.run(:test, ["integration_test"])
  end
end
