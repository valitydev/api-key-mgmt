Mox.defmock(TokenKeeper.Authenticator.MockClient, for: TokenKeeper.Authenticator.Client)
Mox.defmock(TokenKeeper.Authority.MockClient, for: TokenKeeper.Authority.Client)

Application.put_env(:token_keeper, :authenticator_impl, TokenKeeper.Authenticator.MockClient)
Application.put_env(:token_keeper, :authority_impl, TokenKeeper.Authority.MockClient)

ExUnit.start()
