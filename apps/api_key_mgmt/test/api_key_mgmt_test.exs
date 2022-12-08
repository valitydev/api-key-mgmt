defmodule ApiKeyMgmtTest do
  @moduledoc """
  External app tests

  TODO: I never settled on a concrete scope for this case,
  so currently it acts like a combined integration,
  response validation and header handling test case. I probably can
  be split up and/or improved considerably.
  """

  use ExUnit.Case, async: true
  use Plug.Test

  import Mox

  alias ApiKeyMgmt.Router

  setup do
    alias Ecto.Adapters.SQL.Sandbox
    :ok = Sandbox.checkout(ApiKeyMgmt.Repository)
    :ok
  end

  describe "handler response encoding" do
    setup :verify_on_exit!

    test "should follow schema when successfull" do
      TokenKeeper.Authenticator.MockClient
      |> stub(:new, fn ctx -> ctx end)
      |> expect(:authenticate, 6, fn _client, _token, _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "42"})}
      end)

      TokenKeeper.Authority.MockClient
      |> stub(:new, fn _authority, ctx -> ctx end)
      |> expect(:create, 2, fn _client, id, context_fragment, metadata ->
        import TestSupport.TokenKeeper.Helper
        authdata = make_authdata(id, :active, context_fragment, metadata)
        {:ok, %{authdata | token: "42"}}
      end)
      |> expect(:revoke, 1, fn _client, _id ->
        {:ok, nil}
      end)

      Bouncer.MockClient
      |> expect(:judge, 6, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        allowed()
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, 6, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {200, issue_api_key_response} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!()
               )

      issue_body = %{
        "name" => "my_cool_api_key",
        "metadata" => %{
          "with" => "metadata"
        }
      }

      assert {200, issue_api_key_response_metadata} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!()
               )

      assert {200, get_api_key_response} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys/#{issue_api_key_response.id}")
               )

      assert {200, get_api_key_response_metadata} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys/#{issue_api_key_response_metadata.id}")
               )

      assert {200, list_api_keys_response} =
               test_call(:get, get_path("/parties/mypartyid/api-keys"))

      assert {204, nil} =
               test_call(
                 :put,
                 get_path("/parties/mypartyid/api-keys/#{issue_api_key_response.id}/status"),
                 "Revoked" |> Jason.encode!()
               )

      assert :ok == cast_response(200, :issue_api_key, issue_api_key_response)
      assert :ok == cast_response(200, :issue_api_key, issue_api_key_response_metadata)
      assert :ok == cast_response(200, :get_api_key, get_api_key_response)
      assert :ok == cast_response(200, :get_api_key, get_api_key_response_metadata)
      assert :ok == cast_response(200, :list_api_keys, list_api_keys_response)
    end

    test "should follow schema on business errors" do
      TokenKeeper.Authenticator.MockClient
      |> stub(:new, fn ctx -> ctx end)
      |> expect(:authenticate, 1, fn _client, _token, _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "42"})}
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, 1, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      assert {404, nil} =
               test_call(
                 :put,
                 get_path("/parties/mypartyid/api-keys/blah/status"),
                 "Revoked" |> Jason.encode!()
               )
    end

    test "should follow schema when validation fails" do
      api_key_id = "test_key_that_is_way_longer_than_maximim_allowed"

      issue_body = %{}

      assert {400, issue_api_key_response} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!()
               )

      assert {400, get_api_key_response} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys/#{api_key_id}")
               )

      assert {400, list_api_keys_response} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys?status=dontcare")
               )

      assert {400, revoke_api_key_response} =
               test_call(
                 :put,
                 get_path("/parties/mypartyid/api-keys/blah/status"),
                 "Stuff" |> Jason.encode!()
               )

      assert :ok == cast_response(400, :issue_api_key, issue_api_key_response)
      assert :ok == cast_response(400, :get_api_key, get_api_key_response)
      assert :ok == cast_response(400, :list_api_keys, list_api_keys_response)
      assert :ok == cast_response(400, :revoke_api_key, revoke_api_key_response)
    end

    test "should follow schema when authorization fails" do
      TokenKeeper.Authenticator.MockClient
      |> stub(:new, fn ctx -> ctx end)
      |> expect(:authenticate, 4, fn _client, _token, _origin ->
        import TestSupport.TokenKeeper.Helper
        {:ok, make_authdata("42", %{"user.id" => "42"})}
      end)

      OrgManagement.MockClient
      |> expect(:get_user_context, 4, fn _user_id, _ctx ->
        import Bouncer.ContextFragmentBuilder
        {:ok, build() |> bake()}
      end)

      Bouncer.MockClient
      |> expect(:judge, 4, fn _context, _ctx ->
        import TestSupport.Bouncer.Helper
        forbidden()
      end)

      issue_body = %{
        "name" => "my_cool_api_key"
      }

      {:ok, _} = ApiKeyMgmt.ApiKeyRepository.issue("blah", "notmypartyid", "tokenname", "token")

      assert {403, nil} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!()
               )

      assert {403, nil} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys/blah")
               )

      assert {403, nil} = test_call(:get, get_path("/parties/mypartyid/api-keys"))

      assert {403, nil} =
               test_call(
                 :put,
                 get_path("/parties/mypartyid/api-keys/blah/status"),
                 "Revoked" |> Jason.encode!()
               )
    end
  end

  describe "requests with invalid headers" do
    test "should fail when auth headers missing" do
      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {403, _} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!(),
                 [{"content-type", "application/json"}]
               )

      assert {403, _} =
               test_call(
                 :get,
                 get_path("/parties/mypartyid/api-keys/1"),
                 nil,
                 []
               )

      assert {403, _} = test_call(:get, get_path("/parties/mypartyid/api-keys"), nil, [])

      assert {403, _} =
               test_call(
                 :put,
                 get_path("/parties/mypartyid/api-keys/mykeyid/status"),
                 "\"Revoked\"",
                 [{"content-type", "application/json"}]
               )
    end

    test "should fail when content-type header missing" do
      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {415, _} =
               test_call(
                 :post,
                 get_path("/parties/mypartyid/api-keys"),
                 issue_body |> Jason.encode!(),
                 []
               )
    end
  end

  describe "health route" do
    test "/health/startup should reply ok" do
      assert {200, _} =
               test_call(
                 :get,
                 "http://doesnotresolve:8080/health/startup"
               )
    end

    test "/health/liveness should reply ok" do
      assert {200, _} =
               test_call(
                 :get,
                 "http://doesnotresolve:8080/health/liveness"
               )
    end

    test "/health/readiness should reply ok" do
      assert {200, _} =
               test_call(
                 :get,
                 "http://doesnotresolve:8080/health/readiness"
               )
    end
  end

  ###

  defp test_call(method, path, params_or_body \\ nil, headers \\ default_headers()) do
    conn = conn(method, path, params_or_body)

    conn =
      Enum.reduce(headers, conn, fn {k, v}, conn ->
        put_req_header(conn, k, v)
      end)

    conn = router_call(conn)

    resp_body =
      case conn.resp_body do
        "" -> nil
        body -> body |> Jason.decode!(keys: :atoms!)
      end

    {conn.status, resp_body}
  end

  defp get_path(postfix), do: "http://doesnotresolve:8080/apikeys/v1" <> postfix

  defp router_call(conn) do
    Router.call(conn, Router.init([]))
  end

  defp default_headers do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer 42"}
    ]
  end

  defp cast_response(http_code, operation_id, value) do
    alias Plugger.Generated.Spec
    spec = Spec.get()
    response_spec = get_response_spec(spec, http_code, operation_id)

    case OpenApiSpex.cast_value(value, response_spec, spec) do
      {:ok, _castvalue} -> :ok
      err -> err
    end
  end

  defp get_response_spec(spec, 200, :issue_api_key),
    do:
      spec.paths["/parties/{partyId}/api-keys"].post.responses["200"].content["application/json"].schema

  defp get_response_spec(spec, 200, :list_api_keys),
    do:
      spec.paths["/parties/{partyId}/api-keys"].get.responses["200"].content["application/json"].schema

  defp get_response_spec(spec, 200, :get_api_key),
    do:
      spec.paths["/parties/{partyId}/api-keys/{apiKeyId}"].get.responses["200"].content[
        "application/json"
      ].schema

  defp get_response_spec(spec, 400, _anyop),
    do: spec.components.responses["BadRequest"].content["application/json"].schema
end
