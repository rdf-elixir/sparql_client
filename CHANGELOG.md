# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## 0.2.2 - 2019-05-22

### Added

- the `request_opts` options to `SPARQL.Client.query/3` which will be passed as 
 the `opts` option value to the `Tesla.request/2` function



## 0.2.1 - 2018-09-17

### Fixed

- Update to SPARQL.ex 0.2.1 whose Hex package no longer contains Erlang output
  files of Leex and Yecc, which caused issues using the SPARQL.ex Hex package on
  OTP < 21 (because the package was released with OTP 21)

[Compare v0.2.0...v0.2.1](https://github.com/marcelotto/sparql_client/compare/v0.2.0...v0.2.1)



## 0.2.0 - 2018-09-17

### Changed

- adapt to new query result representation in SPARQL.ex 0.2
- Elixir versions < 1.6 are no longer supported (as a consequence of upgrading
  to the latest versions of RDF.ex and SPARQL.ex)


[Compare v0.1.1...v0.2.0](https://github.com/marcelotto/sparql_client/compare/v0.1.1...v0.2.0)


## v0.1.1 - 2018-08-21

- Upgrade to Tesla 1.1

[Compare v0.1.0...v0.1.1](https://github.com/marcelotto/sparql_client/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2018-03-19

Initial release
