defmodule ApiKeyMgmtTest do
  @moduledoc """
  External app tests

  TODO: THIS CASE IS NOT FINISHED
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

  describe "authentication and authorization successfull" do
    setup do
      :ok = expect_authenticator_success(3)
      :ok = expect_authority_success(1)
      :ok = expect_bouncer_success(3)
      :ok = expect_org_management_success(3)
      :ok
    end

    setup :verify_on_exit!

    test "should respond according to schema" do
      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {200, issue_api_key_response} =
               test_call(
                 :post,
                 "http://localhost:8080/parties/mypartyid/api-keys",
                 issue_body |> Jason.encode!()
               )

      assert {200, get_api_key_response} =
               test_call(
                 :get,
                 "http://localhost:8080/parties/mypartyid/api-keys/#{issue_api_key_response.id}"
               )

      assert {200, list_api_keys_response} =
               test_call(:get, "http://localhost:8080/parties/mypartyid/api-keys")

      assert :ok == cast_response(200, :issue_api_key, issue_api_key_response)
      assert :ok == cast_response(200, :get_api_key, get_api_key_response)
      assert :ok == cast_response(200, :list_api_keys, list_api_keys_response)
    end
  end

  describe "invalid headers" do
    test "no auth header" do
      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {403, _} =
               test_call(
                 :post,
                 "http://localhost:8080/parties/mypartyid/api-keys",
                 issue_body |> Jason.encode!(),
                 [{"content-type", "application/json"}]
               )

      assert {403, _} =
               test_call(
                 :get,
                 "http://localhost:8080/parties/mypartyid/api-keys/1",
                 nil,
                 []
               )

      assert {403, _} =
               test_call(:get, "http://localhost:8080/parties/mypartyid/api-keys", nil, [])
    end

    test "no content-type header" do
      issue_body = %{
        "name" => "my_cool_api_key"
      }

      assert {400, _} =
               test_call(
                 :post,
                 "http://localhost:8080/parties/mypartyid/api-keys",
                 issue_body |> Jason.encode!(),
                 []
               )
    end
  end

  defp expect_authenticator_success(times) do
    TokenKeeper.Authenticator.MockClient
    |> stub(:new, fn ctx -> ctx end)
    |> expect(:authenticate, times, fn _client, _token, _origin ->
      import TestSupport.TokenKeeper.Helper
      {:ok, make_authdata("42", %{"user.id" => "42"})}
    end)

    :ok
  end

  defp expect_authority_success(times) do
    TokenKeeper.Authority.MockClient
    |> stub(:new, fn _authority, ctx -> ctx end)
    |> expect(:create, times, fn _client, id, context_fragment, metadata ->
      import TestSupport.TokenKeeper.Helper
      authdata = make_authdata(id, :active, context_fragment, metadata)
      {:ok, %{authdata | token: "42"}}
    end)

    :ok
  end

  defp expect_bouncer_success(times) do
    Bouncer.MockClient
    |> expect(:judge, times, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      allowed()
    end)

    :ok
  end

  defp expect_org_management_success(times) do
    OrgManagement.MockClient
    |> expect(:get_user_context, times, fn _user_id, _ctx ->
      import Bouncer.ContextFragmentBuilder
      {:ok, build() |> bake()}
    end)

    :ok
  end

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
    spec = Plugger.Generated.Spec.get()
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
end
