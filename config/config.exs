import Config

config :api_key_mgmt,
  ecto_repos: [ApiKeyMgmt.Repository]

config :api_key_mgmt, ApiKeyMgmt.Repository, migration_primary_key: [name: :id, type: :string]
config :api_key_mgmt, ApiKeyMgmt.Repository, migration_foreign_key: [name: :id, type: :string]

import_config "#{Mix.env()}.exs"
