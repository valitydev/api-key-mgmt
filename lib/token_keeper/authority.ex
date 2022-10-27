defmodule TokenKeeper.Authority do
  @moduledoc """
  TokenKeeper.Authority service client.
  """
  alias TokenKeeper.{Authority.Client, Identity}

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthDataAlreadyExists,
    AuthDataNotFound
  }

  @spec client(authority_id :: atom(), context :: any()) :: Client.t()
  def client(authority_id, ctx) do
    Client.new(authority_id, ctx)
  end

  @spec create(Client.t(), id :: String.t(), Identity.t(), opts :: Keyword.t() | nil) ::
          {:ok, AuthData.t()} | {:error, {:auth_data, :exists}}
  def create(client, id, identity, opts \\ nil) do
    {context, metadata} =
      Identity.to_context_metadata(identity, metadata_mapping: opts[:metadata_mapping])

    case Client.create(client, id, context, metadata) do
      {:ok, _} = ok -> ok
      {:exception, %AuthDataAlreadyExists{}} -> {:error, {:auth_data, :exists}}
    end
  end

  @spec get(Client.t(), id :: String.t()) ::
          {:ok, AuthData.t()} | {:error, {:auth_data, :not_found}}
  def get(client, id) do
    case Client.get(client, id) do
      {:ok, _} = ok -> ok
      {:exception, %AuthDataNotFound{}} -> {:error, {:auth_data, :not_found}}
    end
  end

  @spec revoke(Client.t(), id :: String.t()) :: :ok | {:error, {:auth_data, :not_found}}
  def revoke(client, id) do
    case Client.revoke(client, id) do
      {:ok, nil} -> :ok
      {:exception, %AuthDataNotFound{}} -> {:error, {:auth_data, :not_found}}
    end
  end
end
