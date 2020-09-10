defmodule SPARQL.Client.HTTPError do
  defexception [:request, :status]

  def message(%{request: request, status: status}) do
    "Request #{inspect(request)} failed with status #{inspect(status)}"
  end
end
