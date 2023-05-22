# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- support for dataset parameters `:using_graph` and `:using_named_graph`
  on update operations

[Compare v0.4.2...HEAD](https://github.com/rdf-elixir/sparql_client/compare/v0.4.2...HEAD)



## v0.4.2 - 2023-04-24

### Added

- support for nimble_options 1.0

### Fixed

- The `:update_request_method` was not correctly fetched from the application config.


[Compare v0.4.1...v0.4.2](https://github.com/rdf-elixir/sparql_client/compare/v0.4.1...v0.4.1)



## v0.4.1 - 2022-11-03

This version is just upgraded to RDF.ex 1.0.

Elixir versions < 1.11 are no longer supported


[Compare v0.4.0...v0.4.1](https://github.com/rdf-elixir/sparql_client/compare/v0.4.0...v0.4.1)



## v0.4.0 - 2022-03-22

With the latest SPARQL.ex version 0.3.7, RDF-star and SPARQL-star results can be handled now.

Elixir versions < 1.10 are no longer supported

### Added

- general `:logger` option on all `SPARQL.Client` functions  
  (instrumenting the `Tesla.Middleware.Logger`)

### Changed

- In consistency with the change in RDF.ex 0.10 to no longer support automatic 
  merges of `RDF.Dataset`s, the `:merge_graphs` option is no longer supported 
  on the `SPARQL.Client.insert_data/3` and `SPARQL.Client.delete_data/3` functions.


[Compare v0.3.1...v0.4.0](https://github.com/rdf-elixir/sparql_client/compare/v0.3.1...v0.4.0)



## v0.3.1 - 2020-11-27

### Added

- support for RDF-XML for graph results 

[Compare v0.3.0...v0.3.1](https://github.com/rdf-elixir/sparql_client/compare/v0.3.0...v0.3.1)



## v0.3.0 - 2020-09-21

Elixir versions < 1.9 are no longer supported

### Added

- raw-mode with the `:raw_mode` option, which allows disabling of the processing of query strings, 
  passing them through as-is to the SPARQL endpoint
- support for `INSERT DATA` and `DELETE DATA` updates with `SPARQL.Client.insert_data/3` and 
  `SPARQL.Client.delete_data/3` which are able to handle all types RDF.ex datastructures 
  (`RDF.Description`, `RDF.Graph`, `RDF.Dataset`) directly 
- support for `LOAD` updates with `SPARQL.Client.load/2` 
- support for `CLEAR` updates with `SPARQL.Client.clear/2` 
- support for all graph management operations with 
  - `SPARQL.Client.create/2` 
  - `SPARQL.Client.drop/2` 
  - `SPARQL.Client.copy/2` 
  - `SPARQL.Client.move/2` 
  - `SPARQL.Client.add/2` 
- the defaults for several options can now be configured globally via the application  
  environment; please refer to the `SPARQL.Client` documentation for more information

### Changed

- the default request method for queries when using SPARQL protocol version 1.1 is now `:get`
- improved error handling

### Fixed

- the default HTTP `Accept` header used when no `:result_form` was provided on 
  `SPARQL.Client.query/3` contained a typo


[Compare v0.2.2...v0.3.0](https://github.com/rdf-elixir/sparql_client/compare/v0.2.2...v0.3.0)



## v0.2.2 - 2019-05-22

### Added

- the `request_opts` options to `SPARQL.Client.query/3` which will be passed as 
 the `opts` option value to the `Tesla.request/2` function

[Compare v0.2.1...v0.2.2](https://github.com/rdf-elixir/sparql_client/compare/v0.2.1...v0.2.2)



## v0.2.1 - 2018-09-17

### Fixed

- Update to SPARQL.ex 0.2.1 whose Hex package no longer contains Erlang output
  files of Leex and Yecc, which caused issues using the SPARQL.ex Hex package on
  OTP < 21 (because the package was released with OTP 21)

[Compare v0.2.0...v0.2.1](https://github.com/rdf-elixir/sparql_client/compare/v0.2.0...v0.2.1)



## v0.2.0 - 2018-09-17

### Changed

- adapt to new query result representation in SPARQL.ex 0.2
- Elixir versions < 1.6 are no longer supported (as a consequence of upgrading
  to the latest versions of RDF.ex and SPARQL.ex)


[Compare v0.1.1...v0.2.0](https://github.com/rdf-elixir/sparql_client/compare/v0.1.1...v0.2.0)


## v0.1.1 - 2018-08-21

- Upgrade to Tesla 1.1

[Compare v0.1.0...v0.1.1](https://github.com/rdf-elixir/sparql_client/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2018-03-19

Initial release
