defmodule OrgManagementClientTest do
  @moduledoc """
  Contains tests for OrgManagement client library. Keep it client implementation agnostic.
  """
  use ExUnit.Case, async: true
  import Mox

  alias Bouncer.Context.ContextFragment
  alias OrgManagement.AuthContextProvider.UserNotFound

  setup :verify_on_exit!

  test "should return context fragment" do
    OrgManagement.MockClient
    |> expect(:get_user_context, fn _user_id, _ctx ->
      {:ok, ContextFragment.new()}
    end)

    assert OrgManagement.get_user_context("user_id", %{}) ==
             {:ok, %ContextFragment{}}
  end

  test "should return an error with {:user, :not_found} reason" do
    OrgManagement.MockClient
    |> expect(:get_user_context, fn _user_id, _ctx ->
      {:exception, UserNotFound.new()}
    end)

    assert OrgManagement.get_user_context("user_id", %{}) ==
             {:error, {:user, :not_found}}
  end
end
