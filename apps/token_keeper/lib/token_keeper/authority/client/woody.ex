defmodule TokenKeeper.Authority.Client.Woody do
  @moduledoc """
  Woody implementation of TokenKeeper.Authenticator.Client
  """
  @behaviour TokenKeeper.Authority.Client

  alias Bouncer.Context.ContextFragment

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthDataAlreadyExists,
    AuthDataNotFound
  }

  alias Woody.Context
  alias Woody.Generated.TokenKeeper.Keeper.TokenAuthority.Client

  @type t() :: Woody.Client.Http.t()

  @spec new(authority_id :: atom(), context :: Context.t()) :: t()
  @impl TokenKeeper.Authority.Client
  def new(authority_id, context) do
    config = Application.fetch_env!(:token_keeper, __MODULE__)
    config = Map.get(config[:authorities], authority_id)

    Client.new(context, config[:url], config[:opts] || [])
  end

  @spec create(
          client :: t(),
          id :: String.t(),
          context_fragment :: ContextFragment.t(),
          metadata :: map()
        ) :: {:ok, AuthData.t()} | {:exception, AuthDataAlreadyExists.t()}
  @impl TokenKeeper.Authority.Client
  def create(client, id, context_fragment, metadata) do
    Client.create(client, id, context_fragment, metadata)
  end

  @spec get(client :: t(), id :: String.t()) ::
          {:ok, AuthData.t()} | {:exception, AuthDataNotFound.t()}
  @impl TokenKeeper.Authority.Client
  def get(client, id) do
    Client.get(client, id)
  end

  @spec revoke(client :: t(), id :: String.t()) :: {:ok, nil} | {:exception, AuthDataNotFound.t()}
  @impl TokenKeeper.Authority.Client
  def revoke(client, id) do
    Client.revoke(client, id)
  end
end
