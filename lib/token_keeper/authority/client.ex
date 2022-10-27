defmodule TokenKeeper.Authority.Client do
  @moduledoc """
  A client behaviour for the TokenKeeper.Authority service client.
  """
  alias TokenKeeper.Authority.Client.Woody

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthDataAlreadyExists,
    AuthDataNotFound
  }

  alias Bouncer.Context.ContextFragment

  @type t() :: any

  @callback new(authority_id :: atom(), context :: any()) :: t()
  @callback create(
              client :: t(),
              id :: String.t(),
              context_fragment :: ContextFragment.t(),
              metadata :: map()
            ) :: {:ok, AuthData.t()} | {:exception, AuthDataAlreadyExists.t()}
  @callback get(client :: t(), id :: String.t()) ::
              {:ok, AuthData.t()} | {:exception, AuthDataNotFound.t()}
  @callback revoke(client :: t(), id :: String.t()) ::
              {:ok, nil} | {:exception, AuthDataNotFound.t()}

  @spec new(authority_id :: atom(), context :: any()) :: t()
  def new(authority_id, ctx) do
    impl().new(authority_id, ctx)
  end

  @spec create(
          client :: t(),
          id :: String.t(),
          context_fragment :: ContextFragment.t(),
          metadata :: map()
        ) :: {:ok, AuthData.t()} | {:exception, AuthDataAlreadyExists.t()}
  def create(client, id, context_fragment, metadata) do
    impl().create(client, id, context_fragment, metadata)
  end

  @spec get(client :: t(), id :: String.t()) ::
          {:ok, AuthData.t()} | {:exception, AuthDataNotFound.t()}
  def get(client, id) do
    impl().get(client, id)
  end

  @spec revoke(client :: t(), id :: String.t()) :: {:ok, nil} | {:exception, AuthDataNotFound.t()}
  def revoke(client, id) do
    impl().revoke(client, id)
  end

  if Mix.env() == :test do
    defp impl,
      do: Application.get_env(:api_key_mgmt, __MODULE__, Woody)
  else
    @client_mod Application.compile_env(:api_key_mgmt, __MODULE__, Woody)
    defp impl,
      do: @client_mod
  end
end
