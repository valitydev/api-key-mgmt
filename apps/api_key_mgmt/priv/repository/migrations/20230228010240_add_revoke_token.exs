defmodule ApiKeyMgmt.Repository.Migrations.AddRevokeToken do
  use Ecto.Migration

  def change do
    alter table(:api_keys) do
      add(:revoke_token, :string)
    end
  end
end
