defmodule TokenKeeper.Authenticator.Client.Woody do
  @moduledoc """
  Woody implementation of TokenKeeper.Authenticator.Client
  """
  @behaviour TokenKeeper.Authenticator.Client

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthDataAlreadyExists,
    AuthDataNotFound,
    AuthDataRevoked,
    InvalidToken,
    TokenSourceContext
  }

  alias Woody.Context
  alias Woody.Generated.TokenKeeper.Keeper.TokenAuthenticator.Client

  @type t() :: Woody.Client.Http.t()

  @spec new(context :: Context.t()) :: t()
  @impl TokenKeeper.Authenticator.Client
  def new(context) do
    config = Application.fetch_env!(:token_keeper, __MODULE__)

    Client.new(context, config[:url], config[:opts] || [])
  end

  @spec authenticate(
          client :: t(),
          token :: String.t(),
          TokenSourceContext.t()
        ) ::
          {:ok, AuthData.t()}
          | {:exception, InvalidToken.t() | AuthDataNotFound.t() | AuthDataRevoked.t()}
  @impl TokenKeeper.Authenticator.Client
  def authenticate(client, token, source_context) do
    Client.authenticate(client, token, source_context)
  end

  @spec add_existing_token(
          client :: t(),
          id :: String.t(),
          context :: Bouncer.Context.ContextFragment.t(),
          metadata :: %{String.t() => String.t()},
          authority :: String.t()
        ) ::
          {:ok, AuthData.t()}
          | {:exception, AuthDataAlreadyExists.t()}
  @impl TokenKeeper.Authenticator.Client
  def add_existing_token(client, id, context, metadata, authority) do
    Client.add_existing_token(client, id, context, metadata, authority)
  end
end
