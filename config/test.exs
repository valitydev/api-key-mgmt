import Config

config :logger, level: :warn

# config :logger, :console,
#   format: {LogstashLoggerFormatter, :format}

# config :logger, :logstash_formatter,
#   level_field: "@severity"

config :api_key_mgmt, ApiKeyMgmt.Repository,
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  database: System.get_env("DB_DATABASE") || "apikeymgmt",
  hostname: System.get_env("DB_HOSTNAME") || "db",
  pool: Ecto.Adapters.SQL.Sandbox
