defmodule SPARQL.Client.HTTPError do
  @moduledoc """
  Exception returned when a HTTP request of a SPARQL protocol operation fails with a non-2XX status.

  The `SPARQL.Client.Request` is included in the exception struct in the `:request` field.
  """

  defexception [:request, :status]

  def message(%{request: request, status: status}) do
    "Request #{inspect(request)} failed with status #{inspect(status)}"
  end
end
