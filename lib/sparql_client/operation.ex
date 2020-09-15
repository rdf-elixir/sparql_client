defmodule SPARQL.Client.Operation do
  @callback init(SPARQL.Client.Request.t(), any, keyword | nil) ::
              {:ok, SPARQL.Client.Request.t()} | {:error, any}

  @callback evaluate_response(SPARQL.Client.Request.t(), keyword | nil) ::
              {:ok, SPARQL.Client.Request.t()} | {:error, any}

  @callback operation_string(SPARQL.Client.Request.t(), keyword | nil) ::
              {:ok, SPARQL.Client.Request.t()} | {:error, any}

  @callback query_parameter_key() :: String.t()
end
