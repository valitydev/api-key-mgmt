defmodule TokenKeeper.Authenticator.Client do
  @moduledoc """
  A client behaviour for the TokenKeeper.Authenticator service client.
  """
  alias TokenKeeper.Authenticator.Client.Woody

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthdataAlreadyExists,
    AuthDataNotFound,
    AuthDataRevoked,
    InvalidToken,
    TokenSourceContext
  }

  @type t() :: any

  @callback new(context :: any()) :: t()
  @callback authenticate(
              client :: t(),
              token :: String.t(),
              TokenSourceContext.t()
            ) ::
              {:ok, AuthData.t()}
              | {:exception, InvalidToken.t() | AuthDataNotFound.t() | AuthDataRevoked.t()}
  @callback add_existing_token(
              client :: t(),
              id :: String.t(),
              context :: Bouncer.Context.ContextFragment.t(),
              metadata :: %{String.t() => String.t()},
              authority :: String.t()
            ) ::
              {:ok, AuthData.t()}
              | {:exception, AuthdataAlreadyExists.t()}

  @spec new(context :: any()) :: t()
  def new(ctx) do
    impl().new(ctx)
  end

  @spec authenticate(
          client :: t(),
          token :: String.t(),
          TokenSourceContext.t()
        ) ::
          {:ok, AuthData.t()}
          | {:exception, InvalidToken.t() | AuthDataNotFound.t() | AuthDataRevoked.t()}
  def authenticate(client, token, source_context) do
    impl().authenticate(client, token, source_context)
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
