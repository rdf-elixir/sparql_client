import Config

config :exvcr,
  vcr_cassette_library_dir: "integration_test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "integration_test/fixtures/custom_cassettes"

config :tesla, :adapter, Tesla.Adapter.Hackney
# config :tesla, :adapter, Tesla.Adapter.Gun
# config :tesla, :adapter, Tesla.Adapter.Mint
