defmodule TokenKeeper.AuthorityTest do
  @moduledoc """
  Contains tests for TokenKeeper.Authority client library. Keep it client implementation agnostic.
  """
  use ExUnit.Case, async: true

  import Mox

  alias TokenKeeper.Authority
  alias TokenKeeper.{Identity, Identity.User}
  alias TokenKeeper.Keeper.{AuthData, AuthDataAlreadyExists, AuthDataNotFound}

  setup :verify_on_exit!

  setup_all %{} do
    Authority.MockClient
    |> Mox.expect(:new, fn _id, ctx -> ctx end)

    %{client: Authority.client("test", %{})}
  end

  test "should create authdata successfully", %{client: client} do
    authdata_id = "42"
    user_id = "user_id"

    Authority.MockClient
    |> expect(:create, fn ^client, ^authdata_id, context, metadata ->
      {:ok,
       %AuthData{
         id: authdata_id,
         context: context,
         metadata: metadata
       }}
    end)

    identity = %Identity{
      type: %User{
        id: user_id
      }
    }

    assert Authority.create(client, authdata_id, identity) ==
             {:ok,
              %AuthData{
                id: authdata_id,
                context: nil,
                metadata: %{"user.id" => user_id}
              }}
  end

  test "should fail to create authdata with error code {:auth_data, :exists}", %{client: client} do
    user_id = "user_id"

    Authority.MockClient
    |> expect(:create, fn ^client, "authdata", nil, %{"user.id" => ^user_id} ->
      {:exception, AuthDataAlreadyExists.new()}
    end)

    identity = %Identity{
      type: %User{
        id: user_id
      }
    }

    assert Authority.create(client, "authdata", identity) ==
             {:error, {:auth_data, :exists}}
  end

  test "should get authdata sucessfully", %{client: client} do
    Authority.MockClient
    |> expect(:get, fn ^client, "authdata" ->
      {:ok, AuthData.new()}
    end)

    assert Authority.get(client, "authdata") ==
             {:ok, AuthData.new()}
  end

  test "should fail to get authdata with error code {:authdata, :not_found}", %{client: client} do
    Authority.MockClient
    |> expect(:get, fn ^client, "authdata" ->
      {:exception, AuthDataNotFound.new()}
    end)

    assert Authority.get(client, "authdata") ==
             {:error, {:auth_data, :not_found}}
  end

  test "should revoke authdata sucessfully", %{client: client} do
    Authority.MockClient
    |> expect(:revoke, fn ^client, "authdata" ->
      {:ok, nil}
    end)

    assert Authority.revoke(client, "authdata") ==
             :ok
  end

  test "should fail to revoke authdata with error code {:authdata, :not_found}", %{client: client} do
    Authority.MockClient
    |> expect(:revoke, fn ^client, "authdata" ->
      {:exception, AuthDataNotFound.new()}
    end)

    assert Authority.revoke(client, "authdata") ==
             {:error, {:auth_data, :not_found}}
  end
end
