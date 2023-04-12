defmodule ApiKeyMgmt.ApiKeyRepository do
  @moduledoc """
  A combo of a Repository and ApiKey schema struct
  """
  alias ApiKeyMgmt.{ApiKey, Repository}

  @spec get(id :: String.t()) :: {:ok, ApiKey.t()} | {:error, :not_found}
  def get(id) do
    case Repository.get(ApiKey, id) do
      nil -> {:error, :not_found}
      found -> {:ok, found}
    end
  end

  @spec list(party_id :: String.t(), opts :: Keyword.t()) ::
          [ApiKey.t()]
  def list(party_id, opts \\ []) do
    require Ecto.Query

    query =
      ApiKey
      |> Ecto.Query.where(party_id: ^party_id)

    query =
      case opts[:status_filter] do
        nil -> query
        status_filter -> query |> Ecto.Query.where(status: ^status_filter)
      end

    Repository.all(query)
  end

  @spec issue(
          id :: String.t(),
          party_id :: String.t(),
          name :: String.t(),
          token :: String.t(),
          metadata :: map() | nil
        ) ::
          {:ok, ApiKey.t()} | {:error, any()}
  def issue(id, party_id, name, token, metadata \\ nil) do
    ApiKey.issue_changeset(id, party_id, name, token, metadata)
    |> Repository.insert()
  end

  @spec set_revoke_token(ApiKeyMgmt.ApiKey.t(), String.t()) :: {:ok, ApiKey.t()} | {:error, any()}
  def set_revoke_token(api_key, revoke_token) do
    api_key
    |> ApiKey.revoke_token_changeset(revoke_token)
    |> Repository.update()
  end

  @spec revoke(ApiKey.t()) :: {:ok, ApiKey.t()} | {:error, any()}
  def revoke(api_key) do
    api_key
    |> ApiKey.revoke_changeset()
    |> Repository.update()
  end
end
