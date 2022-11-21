defmodule TokenKeeper.Authenticator do
  @moduledoc """
  TokenKeeper.Authenticator service client.
  """
  alias TokenKeeper.{Authenticator.Client, Identity}

  alias TokenKeeper.Keeper.{
    AuthDataNotFound,
    AuthDataRevoked,
    InvalidToken,
    TokenSourceContext
  }

  @type error() :: :invalid_token | {:auth_data, :not_found | :revoked}

  @spec client(context :: any()) :: Client.t()
  def client(ctx) do
    Client.new(ctx)
  end

  @spec authenticate(
          Client.t(),
          token :: String.t(),
          request_origin :: String.t()
        ) ::
          {:ok, Identity.t()} | {:error, error()}
  def authenticate(client, token, request_origin) do
    case Client.authenticate(
           client,
           token,
           %TokenSourceContext{request_origin: request_origin}
         ) do
      {:ok, authdata} ->
        {:ok, Identity.from_authdata(authdata)}

      {:exception, %InvalidToken{}} ->
        {:error, :invalid_token}

      {:exception, %AuthDataNotFound{}} ->
        {:error, {:auth_data, :not_found}}

      {:exception, %AuthDataRevoked{}} ->
        {:error, {:auth_data, :revoked}}
    end
  end
end
