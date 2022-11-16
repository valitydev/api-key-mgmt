Mox.defmock(Plugger.Generated.MockHandler, for: Plugger.Generated.Handler)

Mox.defmock(Bouncer.MockClient, for: Bouncer.Client)
Mox.defmock(OrgManagement.MockClient, for: OrgManagement.Client)
Mox.defmock(TokenKeeper.Authenticator.MockClient, for: TokenKeeper.Authenticator.Client)
Mox.defmock(TokenKeeper.Authority.MockClient, for: TokenKeeper.Authority.Client)

Application.put_env(:bouncer, :client_impl, Bouncer.MockClient)
Application.put_env(:org_management, :client_impl, OrgManagement.MockClient)
Application.put_env(:token_keeper, :authenticator_impl, TokenKeeper.Authenticator.MockClient)
Application.put_env(:token_keeper, :authority_impl, TokenKeeper.Authority.MockClient)

Ecto.Adapters.SQL.Sandbox.mode(ApiKeyMgmt.Repository, :manual)

ExUnit.start()
