import Config

# Configure release environment here

config :logger, level: :warn

config :logger, :console,
  #format: {LogstashLoggerFormatter, :format},
  metadata: [
    :event,
    :service,
    :function,
    :type,
    :metadata,
    :url,
    :deadline,
    :execution_duration_ms,
    :trace_id,
    :span_id,
    :parent_id
  ]

config :api_key_mgmt, Plug.Cowboy,
  # Refer to Plug.Cowboy moduledoc for available options
  ip: {0, 0, 0, 0},
  port: 8080

config :api_key_mgmt, ApiKeyMgmt.Handler,
  # * `:deployment_id` - ID of the current deployment used for authorization
  # "Production" by default
  deployment_id: "Production",
  # * `:authority_id` - ID of the authority that issues api keys
  #  Must be configured in token keeper client
  authority_id: "my_authority_id"

config :api_key_mgmt, ApiKeyMgmt.Repository,
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  database: System.get_env("DB_DATABASE") || "apikeymgmt",
  hostname: System.get_env("DB_HOSTNAME") || "db"

config :bouncer, Bouncer.Client.Woody,
  url: "http://bouncer:8022/v1/arbiter",
  ruleset_id: "bouncer_ruleset",
  # WoodyClient.options()
  opts: []

config :org_management, OrgManagement.Client.Woody,
  url: "http://org_management:8022/v1/user_context",
  # WoodyClient.options()
  opts: []

config :token_keeper, TokenKeeper.Authenticator.Client.Woody,
  url: "http://token_keeper:8022/v2/authenticator",
  # WoodyClient.options()
  opts: []

config :token_keeper, TokenKeeper.Authority.Client.Woody, %{
  "my_authority_id" => [
    url: "http://token_keeper:8022/v2/authority/my_authority_id",
    # WoodyClient.options()
    opts: []
  ]
}

config :token_keeper, TokenKeeper.Identity,
  metadata_mapping: %{
    party_id: "party.id",
    user_id: "user.id",
    user_email: "user.email",
    user_realm: "user.realm"
  }
