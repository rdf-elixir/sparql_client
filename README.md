<img src="sparql-logo.png" align="right" />

# SPARQL.Client

[![Hex.pm](https://img.shields.io/hexpm/v/sparql_client.svg?style=flat-square)](https://hex.pm/packages/sparql_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/sparql_client/)
[![Total Download](https://img.shields.io/hexpm/dt/sparql_client.svg)](https://hex.pm/packages/sparql_client)
[![License](https://img.shields.io/hexpm/l/sparql_client.svg)](https://github.com/rdf-elixir/sparql_client/blob/master/LICENSE.md)

[![ExUnit Tests](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-build-and-test.yml/badge.svg)](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-build-and-test.yml)
[![Dialyzer](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-dialyzer.yml/badge.svg)](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-dialyzer.yml)
[![Quality Checks](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-quality-checks.yml/badge.svg)](https://github.com/rdf-elixir/sparql_client/actions/workflows/elixir-quality-checks.yml)


A [SPARQL protocol](https://www.w3.org/TR/sparql11-protocol/) client for Elixir.

The API documentation can be found [here](https://hexdocs.pm/sparql_client/). For a guide and more information about SPARQL.Client and it's related projects, go to <https://rdf-elixir.dev>.


## Features

- Executes all forms of SPARQL queries and updates against any SPARQL 1.0/1.1-compatible endpoint over HTTP
- Validates SPARQL queries before sending them to a SPARQL service endpoint (can be disabled via raw-mode)
- Supports result sets in both XML, JSON, CSV and TSV formats, with JSON being the preferred default for content-negotiation purposes
- Supports graph results in any RDF serialization format understood by [RDF.ex]
- Supports generation of updates (except for `INSERT` and `DELETE` updates), incl. `INSERT/DELETE DATA` updates from all [RDF.ex] data structures
- Works with multiple HTTP client libraries
- Supports interpretation of SPARQL-star results


## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for details.


## Consulting

If you need help with your Elixir and Linked Data projects, just contact [NinjaConcept](https://www.ninjaconcept.com/) via <contact@ninjaconcept.com>.


## License and Copyright

(C) 2018-present Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[SPARQL.Client]:        https://hex.pm/packages/sparql_client
[SPARQL.ex]:            https://hex.pm/packages/sparql
[RDF.ex]:               https://hex.pm/packages/rdf
