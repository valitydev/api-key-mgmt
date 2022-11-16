defmodule ApiKeyMgmt.Repository do
  @moduledoc """
  Ecto repository for the application.
  """
  use Ecto.Repo,
    otp_app: :api_key_mgmt,
    adapter: Ecto.Adapters.Postgres
end
