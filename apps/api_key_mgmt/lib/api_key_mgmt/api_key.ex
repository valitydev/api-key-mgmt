defmodule ApiKeyMgmt.ApiKey do
  @moduledoc """
  A schema struct describing an ApiKey.
  Please note how access_token is required for issue changeset,
  but the field itself is virtual.
  """
  use Ecto.Schema

  @type(status() :: :active, :revoked)
  @type t() :: %__MODULE__{
          __meta__: term(),
          access_token: String.t(),
          id: String.t(),
          inserted_at: DateTime.t(),
          metadata: map(),
          name: String.t(),
          party_id: String.t(),
          status: status(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string
  @timestamps_opts [type: :utc_datetime]

  schema "api_keys" do
    field(:access_token, :string, virtual: true)
    field(:metadata, :map)
    field(:name, :string)
    field(:party_id, :string)
    field(:status, Ecto.Enum, values: [:active, :revoked], default: :active)

    timestamps()
  end

  @spec issue_changeset(
          id :: String.t(),
          party_id :: String.t(),
          name :: String.t(),
          access_token :: String.t(),
          metadata :: map() | nil
        ) :: Ecto.Changeset.t()
  def issue_changeset(id, party_id, name, access_token, metadata \\ nil) do
    # Requiring access_token to be present here feels like both a bad and a good idea
    # Good because it forces an understanding that authdata has to be issued first
    # Bad because unless you know the field is virtual it might seem like it's saved to db
    %__MODULE__{}
    |> changeset(%{
      id: id,
      party_id: party_id,
      access_token: access_token,
      name: name,
      metadata: metadata
    })
  end

  @spec revoke_changeset(t()) :: Ecto.Changeset.t()
  def revoke_changeset(api_key) do
    import Ecto.Changeset
    change(api_key, status: :revoked)
  end

  # TODO: This is a good candidate for protocol use, but Plugger validation mechanics need to be fleshed out first
  @spec encode(t()) :: map()
  def encode(%__MODULE__{} = api_key) do
    %{
      "id" => api_key.id,
      "name" => api_key.name,
      "status" => api_key.status |> to_string() |> String.capitalize(),
      "createdAt" => DateTime.to_iso8601(api_key.inserted_at),
      "accessToken" => api_key.access_token,
      "metadata" => api_key.metadata
    }
    |> Map.reject(fn {_, v} -> v == nil end)
  end

  defp changeset(api_key, attrs) do
    import Ecto.Changeset

    api_key
    |> cast(attrs, [:id, :party_id, :status, :name, :access_token])
    |> validate_required([:id, :party_id, :status, :name, :access_token])
    |> unique_constraint(:id, name: "api_keys_pkey")
  end
end

defimpl ApiKeyMgmt.Auth.BouncerEntity, for: ApiKeyMgmt.ApiKey do
  alias ApiKeyMgmt.ApiKey
  alias Bouncer.Base.Entity

  @spec to_bouncer_entity(ApiKey.t()) :: Entity.t()
  def to_bouncer_entity(api_key) do
    %Entity{
      id: api_key.id,
      party: api_key.party_id,
      type: "ApiKey"
    }
  end
end
