defmodule TokenKeeper.Authenticator.Client.WoodyTest do
  @moduledoc """
  Tests for Woody implementation of TokenKeeper.Authenticator.Client behaviour.
  """
  # Can't run async mode when relying on app env
  use ExUnit.Case, async: false

  alias TestSupport.TokenKeeper.Autheticator.WoodyMock
  alias TestSupport.TokenKeeper.Helper, as: TestHelper
  alias TokenKeeper.Authenticator.Client.Woody, as: Client

  describe "authenticate call" do
    test "should reply ok" do
      token = "42"
      source_context = %TokenKeeper.Keeper.TokenSourceContext{request_origin: "localhost"}

      authdata = TestHelper.make_authdata()

      WoodyMock.mock(
        authenticate: fn ^token, ^source_context ->
          {:ok, authdata}
        end
      )

      assert {:ok, authdata} ==
               Client.new(Woody.Context.new()) |> Client.authenticate(token, source_context)
    end

    test "should reply with an exception" do
      token = "42"
      source_context = %TokenKeeper.Keeper.TokenSourceContext{request_origin: "localhost"}

      WoodyMock.mock(
        authenticate: fn ^token, ^source_context ->
          {:error, %TokenKeeper.Keeper.InvalidToken{}}
        end
      )

      assert {:exception, %TokenKeeper.Keeper.InvalidToken{}} ==
               Client.new(Woody.Context.new()) |> Client.authenticate(token, source_context)
    end
  end

  describe "add_existing_token call" do
    test "should reply ok" do
      id = "42"
      metadata = %{"test" => "test"}
      authority = "test"

      authdata = TestHelper.make_authdata(id, metadata)

      context = authdata.context

      WoodyMock.mock(
        add_existing_token: fn ^id, ^context, ^metadata, ^authority ->
          {:ok, authdata}
        end
      )

      assert {:ok, authdata} ==
               Client.new(Woody.Context.new())
               |> Client.add_existing_token(id, context, metadata, authority)
    end

    test "should reply with an exception" do
      id = "42"
      metadata = %{"test" => "test"}
      authority = "test"

      authdata = TestHelper.make_authdata(id, metadata)

      context = authdata.context

      WoodyMock.mock(
        add_existing_token: fn ^id, ^context, ^metadata, ^authority ->
          {:error, %TokenKeeper.Keeper.AuthDataAlreadyExists{}}
        end
      )

      assert {:exception, %TokenKeeper.Keeper.AuthDataAlreadyExists{}} ==
               Client.new(Woody.Context.new())
               |> Client.add_existing_token(id, context, metadata, authority)
    end
  end
end
