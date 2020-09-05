use Mix.Config

config :exvcr,
  vcr_cassette_library_dir: "integration_test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "integration_test/fixtures/custom_cassettes"

import_config "#{Mix.env()}.exs"
