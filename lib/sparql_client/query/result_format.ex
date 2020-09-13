defmodule SPARQL.Client.Query.ResultFormat do
  @moduledoc false

  def by_name(nil, _), do: nil

  def by_name(name, query_form) when query_form in ~w[select ask]a,
    do: SPARQL.result_format(name)

  def by_name(name, query_form) when query_form in ~w[construct describe]a,
    do: RDF.Serialization.format(name)

  def by_media_type(media_type, query_form) when query_form in ~w[select ask]a,
    do: SPARQL.result_format_by_media_type(media_type)

  def by_media_type(media_type, query_form) when query_form in ~w[construct describe]a,
    do: RDF.Serialization.format_by_media_type(media_type)
end
