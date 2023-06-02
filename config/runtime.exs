import Config

# WoodyClient.options() (aka `woody_client:options/0`)
default_woody_client_options = [
  # DISCUSS consider configuring scoper handler
  #   https://github.com/valitydev/scoper/blob/87110f5bd72c0e39ba9b7d6eca88fea91b8cd357/src/scoper_woody_event_handler.erl
  # See hellgate' `sys.config`
  event_handler: :woody_event_handler_default
]

# Configure release environment here

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

config :api_key_mgmt, ApiKeyMgmt.Email, url: "http://localhost:8022"

config :api_key_mgmt, ApiKeyMgmt.Mailer,
  adapter: Bamboo.LocalAdapter,
  email: "test@example.com"

config :bouncer, Bouncer.Client.Woody,
  url: "http://bouncer:8022/v1/arbiter",
  ruleset_id: "bouncer_ruleset",
  opts: default_woody_client_options

config :org_management, OrgManagement.Client.Woody,
  url: "http://org_management:8022/v1/user_context",
  opts: default_woody_client_options

config :token_keeper, TokenKeeper.Authenticator.Client.Woody,
  url: "http://token_keeper:8022/v2/authenticator",
  opts: default_woody_client_options

config :token_keeper, TokenKeeper.Authority.Client.Woody, %{
  "my_authority_id" => [
    url: "http://token_keeper:8022/v2/authority/my_authority_id",
    opts: default_woody_client_options
  ]
}

config :token_keeper, TokenKeeper.Identity,
  metadata_mapping: %{
    party_id: "party.id",
    user_id: "user.id",
    user_email: "user.email",
    user_realm: "user.realm"
  }
