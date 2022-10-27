defmodule ApiKeyMgmt.Repository.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :metadata, :map
      add :name, :string
      add :organization_id, :string
      add :status, :string

      timestamps()
    end
  end
end
