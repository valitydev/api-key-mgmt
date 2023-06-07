import Config

config :logger, level: :info

config :logger, :console,
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
    :parent_id,
    :request_id
  ]

config :api_key_mgmt,
  ecto_repos: [ApiKeyMgmt.Repository]

config :api_key_mgmt, ApiKeyMgmt.Repository,
  migration_primary_key: [name: :id, type: :string],
  migration_foreign_key: [name: :id, type: :string]

import_config "#{Mix.env()}.exs"
