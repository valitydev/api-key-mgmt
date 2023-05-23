import Config

config :logger, :console, format: {LogstashLoggerFormatter, :format}

# Since `LogstashLoggerFormatter" applies mapping during compilation we have to
# set it up here and not in `config/runtime.exs`.
config :logger, :logstash_formatter,
  level_field: "@severity",
  log_level_map: %{
    emergency: "ERROR",
    alert: "ERROR",
    critical: "ERROR",
    error: "ERROR",
    warning: "WARN",
    notice: "INFO",
    info: "INFO",
    debug: "DEBUG"
  }

config :api_key_mgmt, ApiKeyMgmt.Repository, show_sensitive_data_on_connection_error: false

config :bouncer, client_impl: Bouncer.Client.Woody
config :org_management, client_impl: OrgManagement.Client.Woody
config :token_keeper, authenticator_impl: TokenKeeper.Authenticator.Client.Woody
config :token_keeper, authority_impl: TokenKeeper.Authority.Client.Woody
