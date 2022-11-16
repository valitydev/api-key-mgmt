defmodule ApiKeyMgmt.ApiKeyRepositoryTest do
  @moduledoc """
    Tests for ApiKeyRepository module.
  """
  use ExUnit.Case, async: true

  alias ApiKeyMgmt.ApiKey
  alias ApiKeyMgmt.ApiKeyRepository

  setup do
    alias Ecto.Adapters.SQL.Sandbox
    :ok = Sandbox.checkout(ApiKeyMgmt.Repository)
  end

  test "should fail getting by random id" do
    assert {:error, :not_found} == ApiKeyRepository.get("42")
  end

  test "should issue and get" do
    {:ok, apikey1} = issue()
    {:ok, apikey2} = ApiKeyRepository.get(apikey1.id)

    assert %{apikey1 | access_token: nil} == apikey2
  end

  test "should fail issuing with the same id" do
    assert match?({:ok, _}, issue())
    assert match?({:error, _}, issue())
  end

  test "should fail issuing with invalid access token" do
    assert match?({:error, _}, issue("test_id1", "test_org1", "test_name1", ""))
  end

  test "should issue multiple and list" do
    {:ok, apikey1} = issue("test_id1", "test_org1", "test_name1")
    {:ok, apikey2} = issue("test_id2", "test_org1", "test_name2")
    {:ok, apikey3} = issue("test_id3", "test_org2", "test_name3")

    ## Remove access tokens because list ops dont return them
    apikey1 = %{apikey1 | access_token: nil}
    apikey2 = %{apikey2 | access_token: nil}
    apikey3 = %{apikey3 | access_token: nil}

    assert {:ok, [apikey1, apikey2]} == ApiKeyRepository.list("test_org1")
    assert {:ok, [apikey3]} == ApiKeyRepository.list("test_org2")
    assert {:error, :not_found} == ApiKeyRepository.list("test_org3")
  end

  test "should issue and revoke" do
    {:ok, apikey} = issue()

    {:ok, apikey} = ApiKeyRepository.revoke(apikey)
    assert match?(%ApiKey{status: :revoked}, apikey)
  end

  test "should issue multiple, revoke and list with a filter" do
    {:ok, apikey1} = issue("test_id1", "test_org1")
    {:ok, apikey2} = issue("test_id2", "test_org1")

    {:ok, apikey2} = ApiKeyRepository.revoke(apikey2)

    ## Remove access tokens because list ops dont return them
    apikey1 = %{apikey1 | access_token: nil}
    apikey2 = %{apikey2 | access_token: nil}

    assert {:ok, [apikey1]} == ApiKeyRepository.list("test_org1", status_filter: :active)
    assert {:ok, [apikey2]} == ApiKeyRepository.list("test_org1", status_filter: :revoked)
  end

  defp issue(
         id \\ "test_id",
         org_id \\ "test_org",
         key_name \\ "test_name",
         access_token \\ "test_token"
       ) do
    ApiKeyRepository.issue(id, org_id, key_name, access_token)
  end
end
