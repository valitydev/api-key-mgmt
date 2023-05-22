defmodule ApiKeyMgmt.HandlerTest do
  @moduledoc """
  Tests for service handler.
  """
  use ExUnit.Case, async: true

  import Mox

  alias ApiKeyMgmt.ApiKeyRepository
  alias ApiKeyMgmt.Auth.BouncerEntity
  alias ApiKeyMgmt.Handler
  alias Plugger.Generated.Auth.SecurityScheme.Bearer

  alias Plugger.Generated.Response.{
    Forbidden,
    GetApiKeyOk,
    IssueApiKeyOk,
    ListApiKeysOk,
    NotFound,
    RevokeApiKeyNoContent
  }

  alias TokenKeeper.{Authenticator, Authority}
  alias TokenKeeper.Keeper.{AuthData, AuthDataNotFound}

  @test_authority_id "test_authority"

  setup_all do
    Application.put_env(:api_key_mgmt, Handler, authority_id: @test_authority_id)
  end

  setup do
    alias Ecto.Adapters.SQL.Sandbox
    :ok = Sandbox.checkout(ApiKeyMgmt.Repository)
  end

  setup :verify_on_exit!
  setup :make_test_handler_context
  setup :authenticate_test_handler_context!

  describe "__authenticate__" do
    test "should return deny when auth fails", ctx do
      Authenticator.MockClient
      |> expect(:new, fn ctx -> ctx end)
      |> expect(:authenticate, fn _client, "42", _origin ->
        {:exception, AuthDataNotFound.new()}
      end)

      assert :deny == Handler.__authenticate__(%Bearer{token: "42"}, ctx.raw_handler_ctx)
    end
  end

  describe "get_api_key" do
    test "should return an Ok response with an ApiKey", ctx do
      party_id = "test_party"
      key_id = "test_id"
      name = "test_name"
      {:ok, apikey} = repo_issue(key_id, party_id, name)

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          context_fragment
          |> assert_apikeymgmt("GetApiKey", party_id, key_id)
          |> assert_entity(BouncerEntity.to_bouncer_entity(apikey))
        end)

        allowed()
      end)

      result = Handler.get_api_key(party_id, key_id, ctx.handler_ctx)

      assert match?(
               %GetApiKeyOk{
                 content: %{
                   "id" => ^key_id,
                   "name" => ^name,
                   "status" => "Active"
                 }
               },
               result
             )

      assert ["createdAt", "id", "name", "status"] == Map.keys(result.content)
    end

    test "should return a Forbidden response when operation was forbidden", ctx do
      {:ok, apikey} = repo_issue()

      Bouncer.MockClient
      |> expect(:judge, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        forbidden()
      end)

      assert %Forbidden{} ==
               Handler.get_api_key("test_party", apikey.id, ctx.handler_ctx)
    end

    test "should return a NotFound response when key was not found", ctx do
      assert %NotFound{} == Handler.get_api_key("party_id", "test_id", ctx.handler_ctx)
    end
  end

  describe "issue_api_key" do
    test "should return an Ok response", ctx do
      party_id = "party_id"
      name = "My Key"
      access_token = "42"
      key_metadata = %{"cool" => "stuff"}

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          assert_apikeymgmt(context_fragment, "IssueApiKey", party_id)
        end)

        allowed()
      end)

      Authority.MockClient
      |> expect(:new, fn @test_authority_id, ctx -> ctx end)
      |> expect(:create, fn _client, id, context_fragment, metadata ->
        import TestSupport.Bouncer.Helper

        context_fragment
        |> assert_fragment(fn fragment ->
          fragment
          |> assert_auth("ApiKeyToken", nil, id, party: party_id)
        end)

        assert %{"party.id" => party_id} == metadata

        {:ok,
         %TokenKeeper.Keeper.AuthData{
           id: id,
           token: access_token,
           context: context_fragment,
           metadata: metadata
         }}
      end)

      result =
        Handler.issue_api_key(party_id, %{name: name, metadata: key_metadata}, ctx.handler_ctx)

      assert match?(
               %IssueApiKeyOk{
                 content: %{
                   "name" => ^name,
                   "status" => "Active",
                   "accessToken" => ^access_token,
                   "metadata" => ^key_metadata
                 }
               },
               result
             )

      assert ["accessToken", "createdAt", "id", "metadata", "name", "status"] ==
               Map.keys(result.content)
    end

    test "should return a Forbidden response when operation is forbidden", ctx do
      Bouncer.MockClient
      |> expect(:judge, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        forbidden()
      end)

      assert %Forbidden{} ==
               Handler.issue_api_key("party_id", %{name: "My Key"}, ctx.handler_ctx)
    end
  end

  describe "list_api_keys" do
    test "should return an Ok response", ctx do
      party_id = "test_party"
      {:ok, apikey1} = repo_issue("test_id1", party_id, "test_name")
      {:ok, apikey2} = repo_issue("test_id2", party_id, "test_name")
      {:ok, apikey2} = ApiKeyRepository.revoke(apikey2)

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          assert_apikeymgmt(context_fragment, "ListApiKeys", party_id)
        end)

        allowed()
      end)

      assert %ListApiKeysOk{
               content: %{
                 "results" => [
                   encode_api_key(%{apikey1 | access_token: nil}),
                   encode_api_key(%{apikey2 | access_token: nil})
                 ]
               }
             } ==
               Handler.list_api_keys(party_id, [], ctx.handler_ctx)
    end

    test "should return an Ok response and a filtered list of api keys", ctx do
      party_id = "test_party"
      {:ok, _apikey1} = repo_issue("test_id1", party_id, "test_name")
      {:ok, apikey2} = repo_issue("test_id2", party_id, "test_name")
      {:ok, apikey2} = ApiKeyRepository.revoke(apikey2)

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          assert_apikeymgmt(context_fragment, "ListApiKeys", party_id)
        end)

        allowed()
      end)

      assert %ListApiKeysOk{
               content: %{
                 "results" => [
                   encode_api_key(%{apikey2 | access_token: nil})
                 ]
               }
             } ==
               Handler.list_api_keys(party_id, [status: :revoked], ctx.handler_ctx)
    end

    test "should return a Forbidden response when operation was forbiden", ctx do
      party_id = "test_party"
      {:ok, _apikey} = repo_issue("test_id", party_id, "test_name")

      Bouncer.MockClient
      |> expect(:judge, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        forbidden()
      end)

      assert %Forbidden{} == Handler.list_api_keys(party_id, [], ctx.handler_ctx)
    end

    test "should return an empty list of results when no keys are found", ctx do
      party_id = "test_party"

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          assert_apikeymgmt(context_fragment, "ListApiKeys", party_id)
        end)

        allowed()
      end)

      assert %ListApiKeysOk{
               content: %{
                 "results" => []
               }
             } ==
               Handler.list_api_keys(party_id, [], ctx.handler_ctx)
    end
  end

  describe "request_revoke_api_key" do
    test "should return a NoContent response", ctx do
      party_id = "test_party"
      key_id = "test_id"
      {:ok, apikey} = repo_issue(key_id, party_id, "test_name")

      Bouncer.MockClient
      |> expect(:judge, fn context, _ctx ->
        import TestSupport.Bouncer.Helper

        assert_context(context, fn %{"api-key-mgmt" => context_fragment} ->
          context_fragment
          |> assert_apikeymgmt("RevokeApiKey", party_id, key_id)
          |> assert_entity(BouncerEntity.to_bouncer_entity(apikey))
        end)

        allowed()
      end)

      Authenticator.MockClient
      |> expect(:new, fn ctx -> ctx end)
      |> expect(:authenticate, fn _client, "43", _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "43", "user.email" => "example42@email.com"})}
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      {:allow, ctx} = Handler.__authenticate__(%Bearer{token: "43"}, ctx.raw_handler_ctx)

      assert %RevokeApiKeyNoContent{} ==
               Handler.request_revoke_api_key(party_id, key_id, "Revoked", ctx)
    end

    test "should return a Forbidden response when identity unknown", ctx do
      assert %Forbidden{} ==
               Handler.request_revoke_api_key(
                 "test_party",
                 "test_id",
                 "Revoked",
                 ctx.raw_handler_ctx
               )
    end

    test "should return a Forbidden response when operation was forbidden", ctx do
      party_id = "test_party"
      key_id = "test_id"
      {:ok, _apikey} = repo_issue(key_id, party_id, "test_name")

      Authenticator.MockClient
      |> expect(:new, fn ctx -> ctx end)
      |> expect(:authenticate, fn _client, "43", _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "43", "user.email" => "example42@email.com"})}
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      {:allow, ctx} = Handler.__authenticate__(%Bearer{token: "43"}, ctx.raw_handler_ctx)

      Bouncer.MockClient
      |> expect(:judge, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        forbidden()
      end)

      assert %Forbidden{} ==
               Handler.request_revoke_api_key(party_id, key_id, "Revoked", ctx)
    end

    test "should return a NotFound response when api key is not found", ctx do
      Authenticator.MockClient
      |> expect(:new, fn ctx -> ctx end)
      |> expect(:authenticate, fn _client, "43", _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "43", "user.email" => "example42@email.com"})}
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      {:allow, ctx} = Handler.__authenticate__(%Bearer{token: "43"}, ctx.raw_handler_ctx)

      assert %NotFound{} ==
               Handler.request_revoke_api_key("party_id", "api_key_id", "Revoked", ctx)
    end
  end

  ##

  defp make_test_handler_context(_testctx) do
    use Plug.Test

    conn = conn(:get, "/")

    ctx = Handler.__init__(conn)

    %{raw_handler_ctx: ctx}
  end

  defp authenticate_test_handler_context!(%{raw_handler_ctx: ctx}) do
    Authenticator.MockClient
    |> expect(:new, fn ctx -> ctx end)
    |> expect(:authenticate, fn _client, "42", _origin ->
      import Bouncer.ContextFragmentBuilder

      {:ok, %AuthData{context: build() |> bake()}}
    end)

    {:allow, ctx} = Handler.__authenticate__(%Bearer{token: "42"}, ctx)

    %{handler_ctx: ctx}
  end

  defp repo_issue(
         id \\ "test_id",
         party_id \\ "test_party",
         key_name \\ "test_name",
         access_token \\ "test_token",
         metadata \\ nil
       ) do
    ApiKeyRepository.issue(id, party_id, key_name, access_token, metadata)
  end

  defp encode_api_key(api_key) do
    alias ApiKeyMgmt.ApiKey
    ApiKey.encode(api_key)
  end
end
