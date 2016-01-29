use Mix.Config

import_config "#{Mix.env}.exs"

config :toniq, redis_url: "redis://localhost:6379/0"
config :toniq, retry_strategy: Toniq.RetryWithoutDelayStrategy
