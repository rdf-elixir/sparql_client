<img src="sparql-logo.png" align="right" />

# SPARQL.Client

[![CI](https://github.com/rdf-elixir/sparql_client/workflows/CI/badge.svg?branch=master)](https://github.com/rdf-elixir/sparql_client/actions?query=branch%3Amaster+workflow%3ACI)
[![Hex.pm](https://img.shields.io/hexpm/v/sparql_client.svg?style=flat-square)](https://hex.pm/packages/sparql_client)


A [SPARQL protocol](https://www.w3.org/TR/sparql11-protocol/) client for Elixir.

The API documentation can be found [here](https://hexdocs.pm/sparql_client/). For a guide and more information about SPARQL.Client and it's related projects, go to <https://rdf-elixir.dev>.


## Features

- executes all forms of SPARQL queries and updates against any SPARQL 1.0/1.1-compatible endpoint over HTTP
- validates SPARQL queries before sending them to a SPARQL service endpoint (can be disabled via raw-mode) 
- supports result sets in both XML, JSON, CSV and TSV formats, with JSON being the preferred default for content-negotiation purposes
- supports graph results in any RDF serialization format understood by [RDF.ex]
- supports generation of updates (except for `INSERT` and `DELETE` updates), incl. `INSERT/DELETE DATA` updates from all [RDF.ex] data structures   
- works with multiple HTTP client libraries


## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.


## Consulting and Partnership

If you need help with your Elixir and Linked Data projects, just contact <info@cokron.com> or visit <https://www.cokron.com/kontakt>


## License and Copyright

(c) 2018-2020 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[SPARQL.Client]:        https://hex.pm/packages/sparql_client
[SPARQL.ex]:            https://hex.pm/packages/sparql
[RDF.ex]:               https://hex.pm/packages/rdf
