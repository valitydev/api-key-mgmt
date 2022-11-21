defmodule TokenKeeper.AuthenticatorTest do
  @moduledoc """
  Contains tests for TokenKeeper.Authenticator client library. Keep it client implementation agnostic.
  """
  use ExUnit.Case, async: true

  import Mox

  alias TokenKeeper.Authenticator
  alias TokenKeeper.Identity

  alias TokenKeeper.Keeper.{
    AuthData,
    AuthDataNotFound,
    AuthDataRevoked,
    InvalidToken,
    TokenSourceContext
  }

  setup :verify_on_exit!

  setup_all %{} do
    Authenticator.MockClient
    |> Mox.expect(:new, fn ctx -> ctx end)

    %{client: Authenticator.client(%{})}
  end

  test "should return unknown identity type", %{client: client} do
    Authenticator.MockClient
    |> expect(:authenticate, fn ^client,
                                "token",
                                %TokenSourceContext{request_origin: "http://origin"} ->
      {:ok, AuthData.new()}
    end)

    assert Authenticator.authenticate(client, "token", "http://origin") ==
             {:ok, %Identity{type: :unknown}}
  end

  test "should return an error with :invalid_token reason", %{client: client} do
    Authenticator.MockClient
    |> expect(:authenticate, fn ^client, _token, _origin ->
      {:exception, InvalidToken.new()}
    end)

    assert Authenticator.authenticate(client, "token", "http://origin") ==
             {:error, :invalid_token}
  end

  test "should return an error with {:auth_data, :not_found} reason", %{client: client} do
    Authenticator.MockClient
    |> expect(:authenticate, fn ^client, _token, _origin ->
      {:exception, AuthDataNotFound.new()}
    end)

    assert Authenticator.authenticate(client, "token", "http://origin") ==
             {:error, {:auth_data, :not_found}}
  end

  test "should return an error with {:auth_data, :revoked} reason", %{client: client} do
    Authenticator.MockClient
    |> expect(:authenticate, fn ^client, _token, _origin ->
      {:exception, AuthDataRevoked.new()}
    end)

    assert Authenticator.authenticate(client, "token", "http://origin") ==
             {:error, {:auth_data, :revoked}}
  end
end
