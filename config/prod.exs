import Config

config :bouncer, client_impl: Bouncer.Client.Woody
config :org_management, client_impl: OrgManagement.Client.Woody
config :token_keeper, authenticator_impl: TokenKeeper.Authenticator.Client.Woody
config :token_keeper, authority_impl: TokenKeeper.Authority.Client.Woody
