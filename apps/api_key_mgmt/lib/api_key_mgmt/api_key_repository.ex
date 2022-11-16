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

  @spec list(org_id :: String.t(), opts :: Keyword.t()) ::
          {:ok, [ApiKey.t()]} | {:error, :not_found}
  def list(org_id, opts \\ []) do
    require Ecto.Query

    query =
      ApiKey
      |> Ecto.Query.where(organization_id: ^org_id)

    query =
      case opts[:status_filter] do
        nil -> query
        status_filter -> query |> Ecto.Query.where(status: ^status_filter)
      end

    case query |> Repository.all() do
      [_ | _] = found -> {:ok, found}
      [] -> {:error, :not_found}
    end
  end

  @spec issue(
          id :: String.t(),
          org_id :: String.t(),
          name :: String.t(),
          token :: String.t()
        ) ::
          {:ok, ApiKey.t()} | {:error, any()}
  def issue(id, org_id, name, token) do
    ApiKey.issue_changeset(id, org_id, name, token)
    |> Repository.insert()
  end

  @spec revoke(ApiKey.t()) :: {:ok, ApiKey.t()} | {:error, any()}
  def revoke(api_key) do
    api_key
    |> ApiKey.revoke_changeset()
    |> Repository.update()
  end
end
