Mox.defmock(Plugger.Generated.MockHandler, for: Plugger.Generated.Handler)
Mox.defmock(Bouncer.MockClient, for: Bouncer.Client)
Mox.defmock(TokenKeeper.Authenticator.MockClient, for: TokenKeeper.Authenticator.Client)
Mox.defmock(TokenKeeper.Authority.MockClient, for: TokenKeeper.Authority.Client)
Mox.defmock(OrgManagement.MockClient, for: OrgManagement.Client)

Application.put_env(:api_key_mgmt, :bouncer_impl, Bouncer.MockClient)

Application.put_env(
  :api_key_mgmt,
  TokenKeeper.Authenticator.Client,
  TokenKeeper.Authenticator.MockClient
)

Application.put_env(
  :api_key_mgmt,
  TokenKeeper.Authority.Client,
  TokenKeeper.Authority.MockClient
)

Application.put_env(:api_key_mgmt, :org_management_impl, OrgManagement.MockClient)

Ecto.Adapters.SQL.Sandbox.mode(ApiKeyMgmt.Repository, :manual)

ExUnit.start()
