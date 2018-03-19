# SPARQL.Client

[![Travis](https://img.shields.io/travis/marcelotto/sparql_client.svg?style=flat-square)](https://travis-ci.org/marcelotto/sparql_client)
[![Hex.pm](https://img.shields.io/hexpm/v/sparql_client.svg?style=flat-square)](https://hex.pm/packages/sparql_client)


A [SPARQL protocol](https://www.w3.org/TR/sparql11-protocol/) client for Elixir.


## Features

- Executes all forms of SPARQL queries against any SPARQL 1.0/1.1-compatible endpoint over HTTP.
- Supports result sets in both XML, JSON, CSV and TSV formats, with JSON being the preferred default for content-negotiation purposes.
- Supports graph results in any RDF serialization format understood by [RDF.ex].
- Works with multiple HTTP client libraries.


## Installation

The [SPARQL.Client] Hex package can be installed as usual, by adding `sparql_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sparql_client, "~> 0.1"}
  ]
end
```


## Usage

The major function of the SPARQL.Client is `SPARQL.Client.query/3` to perform the various forms of SPARQL queries. It takes a string with a SPARQL query, a URL of a SPARQL endpoint and some options. The query is only sent to the endpoint if it is syntactically valid. Depending on the query form either a `SPARQL.Query.ResultSet` struct is returned or an `RDF.Graph`.

For a more detailed description, including the various `SPARQL.Client.query/3` options, see its [documentation](http://hexdocs.pm/sparql_client/SPARQL.Client.html#query/3).


## Examples

### `SELECT` query

```elixir
# Places with free wi-fi from Wikidata

"""
SELECT ?item ?itemLabel (SAMPLE(?coord) AS ?coord)
WHERE {
	?item wdt:P2848 wd:Q1543615 ;  # wi-fi gratis
	      wdt:P625 ?coord .
	SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en" }
} GROUP BY ?item ?itemLabel
LIMIT 100
"""
|> SPARQL.Client.query("https://query.wikidata.org/bigdata/namespace/wdq/sparql")
```

`SELECT` query results are returned as a `SPARQL.Query.ResultSet` struct:

```elixir
{:ok, %SPARQL.Query.ResultSet{
   results: [
     %SPARQL.Query.Result{
       bindings: %{
         "coord" => ~L"Point(23.32527778 42.695)",
         "item" => ~I<http://www.wikidata.org/entity/Q5123174>,
         "itemLabel" => ~L"City Garden"en
       }
     },
     %SPARQL.Query.Result{
       bindings: %{
         "coord" => ~L"Point(24.74138889 42.13444444)",
         "item" => ~I<http://www.wikidata.org/entity/Q7205164>,
         "itemLabel" => ~L"Plovdiv Central railway station"en
       }
     },
     %SPARQL.Query.Result{
       bindings: %{
         "coord" => ~L"Point(27.9122 43.1981)",
         "item" => ~I<http://www.wikidata.org/entity/Q7916008>,
         "itemLabel" => ~L"Varna railway station"en
       }
     },
     %SPARQL.Query.Result{
       bindings: %{
         "coord" => ~L"Point(23.31966111 42.69133056)",
         "item" => ~I<http://www.wikidata.org/entity/Q7937209>,
         "itemLabel" => ~L"Vitosha Boulevard"en
       }
     },
     ...
   ],
   variables: ["item", "itemLabel", "coord"]
 }
} 
```

### `ASK` query

```elixir
"""
PREFIX : <http://dbpedia.org/resource/>
PREFIX dbo: <http://dbpedia.org/ontology/>

ASK {:Sleepers dbo:starring :Kevin_Bacon }
"""
|> SPARQL.Client.query("http://dbpedia.org/sparql")
```

`ASK` query results are also returned as a `SPARQL.Query.ResultSet` struct, but with the `results` field containing just the boolean result value.

```elixir
{:ok, %SPARQL.Query.ResultSet{results: true, variables: nil}}
```


### `DESCRIBE` query

```elixir
"DESCRIBE <http://dbpedia.org/resource/Elixir_(programming_language)>"
|> SPARQL.Client.query("http://dbpedia.org/sparql")
```

`DESCRIBE` query results are returned as an `RDF.Graph` resp. as an `RDF.Dataset` if the format returned by the server supports quads.

```elixir
{:ok, #RDF.Graph{name: nil
      ~I<http://dbpedia.org/resource/Elixir_(programming_language)>
          ~I<http://dbpedia.org/ontology/influenced>
              ~I<http://dbpedia.org/resource/LFE_(programming_language)>
          ~I<http://dbpedia.org/ontology/influencedBy>
              ~I<http://dbpedia.org/resource/Clojure>
              ~I<http://dbpedia.org/resource/Erlang_(programming_language)>
              ~I<http://dbpedia.org/resource/LFE_(programming_language)>
              ~I<http://dbpedia.org/resource/Ruby_(programming_language)>
          ~I<http://dbpedia.org/ontology/license>
              ~I<http://dbpedia.org/resource/Apache_License>
          ~I<http://dbpedia.org/property/creator>
              ~I<http://dbpedia.org/resource/José_Valim>
          ~I<http://dbpedia.org/property/platform>
              ~I<http://dbpedia.org/resource/Erlang_(programming_language)>
          ~I<http://purl.org/linguistics/gold/hypernym>
              ~I<http://dbpedia.org/resource/Language>
          ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
              ~I<http://dbpedia.org/class/yago/Abstraction100002137>
              ~I<http://dbpedia.org/class/yago/ArtificialLanguage106894544>
              ~I<http://dbpedia.org/class/yago/Communication100033020>
              ~I<http://dbpedia.org/class/yago/Language106282651>
              ~I<http://dbpedia.org/class/yago/ProgrammingLanguage106898352>
              ~I<http://dbpedia.org/class/yago/WikicatProgrammingLanguages>
              ~I<http://dbpedia.org/class/yago/WikicatProgrammingLanguagesCreatedInThe2010s>
              ~I<http://dbpedia.org/ontology/Language>
              ~I<http://dbpedia.org/ontology/ProgrammingLanguage>
              ~I<http://schema.org/Language>
              ~I<http://www.w3.org/2002/07/owl#Thing>
              ~I<http://www.wikidata.org/entity/Q315>
              ~I<http://www.wikidata.org/entity/Q34770>
              ~I<http://www.wikidata.org/entity/Q9143>
          ~I<http://xmlns.com/foaf/0.1/homepage>
              ~I<http://elixir-lang.org>
          ~I<http://xmlns.com/foaf/0.1/name>
              ~L"Elixir"en
    ...
 }    
}  
```

### `CONSTRUCT` query

```elixir
"""
PREFIX : <http://example.org/>
PREFIX dbo: <http://dbpedia.org/ontology/>
PREFIX dbp: <http://dbpedia.org/property/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>

CONSTRUCT { 
    :Elixir
        :name     ?name ;
        :homepage ?homepage ;
        :license  ?license ;
        :creator  ?creator .
}
WHERE  { 
    <http://dbpedia.org/resource/Elixir_(programming_language)> 
        foaf:name     ?name ;
        foaf:homepage ?homepage ;
        dbp:creator   ?creator ;
        dbo:license   ?license .
}
""" 
|> SPARQL.Client.query("http://dbpedia.org/sparql")
```

`CONSTRUCT` query results are also returned as an `RDF.Graph` resp. as an `RDF.Dataset` if the format returned by the server supports quads.

```elixir
{:ok, #RDF.Graph{name: nil
      ~I<http://example.org/Elixir>
          ~I<http://example.org/creator>
              ~I<http://dbpedia.org/resource/José_Valim>
          ~I<http://example.org/homepage>
              ~I<http://elixir-lang.org>
          ~I<http://example.org/license>
              ~I<http://dbpedia.org/resource/Apache_License>
          ~I<http://example.org/name>
              ~L"Elixir"en}}
```



## Configuration

SPARQL.Client uses [Tesla](https://github.com/teamon/tesla), an abstraction over different HTTP client libraries. This allows you to use the HTTP client of your choice, as long as a Tesla adapter exists, currently httpc, [hackney](https://github.com/benoitc/hackney) or [ibrowse](https://github.com/cmullaparthi/ibrowse). 

Without further configuration, the built-in Erlang httpc is used. For simple tests or if you want to keep your dependencies clean you can go with that, but I recommend using one of the alternatives. I've experienced encoding related issues with httpc, which none of the other HTTP clients had.

If you want to use another client library, you'll have to add it to your list of dependencies in `mix.exs` and configure Tesla to use it.

So, for hackney you'll have to add `hackney` to `mix.exs`:

```elixir
def deps do
  [
    {:sparql_client, "~> 0.1"},
    {:hackney, "~> 1.6"}
  ]
end
```

and add this line to your `config.exs` file (or environment specific configuration):

```elixir
config :tesla, :adapter, :hackney
```

The ibrowse configuration looks similarly.

`mix.exs`:

```elixir
def deps do
  [
    {:sparql_client, "~> 0.1"},
    {:ibrowse, "~> 4.2"}
  ]
end
```

`config.exs`:

```elixir
config :tesla, :adapter, :ibrowse
```


## Getting help

- [Documentation](http://hexdocs.pm/sparql_client)
- [Google Group](https://groups.google.com/d/forum/rdfex)


## Contributing

see [CONTRIBUTING](CONTRIBUTING.md) for details.


## License and Copyright

(c) 2018 Marcel Otto. MIT Licensed, see [LICENSE](LICENSE.md) for details.


[SPARQL.Client]:        https://hex.pm/packages/sparql_client
[SPARQL.ex]:            https://hex.pm/packages/sparql
[RDF.ex]:               https://hex.pm/packages/rdf
[JSON-LD.ex]:           https://hex.pm/packages/json_ld  
[N-Triples]:            https://www.w3.org/TR/n-triples/
[N-Quads]:              https://www.w3.org/TR/n-quads/
[Turtle]:               https://www.w3.org/TR/turtle/
[JSON-LD]:              http://www.w3.org/TR/json-ld/
[RDF-XML]:              https://www.w3.org/TR/rdf-syntax-grammar/
