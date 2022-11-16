import Config

# Configure release environment here

config :api_key_mgmt, Plug.Cowboy,
  # Refer to Plug.Cowboy moduledoc for available options
  ip: {0, 0, 0, 0},
  port: 8080

config :api_key_mgmt, ApiKeyMgmt.Handler,
  # * `:authority_id` - ID of the authority that issues api keys
  #  Must be configured in token keeper client
  authority_id: "my_authority_id"

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
