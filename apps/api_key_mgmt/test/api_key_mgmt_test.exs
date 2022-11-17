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

    TokenKeeper.Authenticator.MockClient
    |> stub(:new, fn ctx -> ctx end)
    |> stub(:authenticate, fn _client, _token, _origin ->
      import TestSupport.TokenKeeper.Helper
      {:ok, make_authdata()}
    end)

    TokenKeeper.Authority.MockClient
    |> stub(:new, fn _authority, ctx -> ctx end)
    |> stub(:create, fn _client, id, context_fragment, metadata ->
      import TestSupport.TokenKeeper.Helper
      authdata = make_authdata(id, :active, context_fragment, metadata)
      {:ok, %{authdata | token: "42"}}
    end)

    Bouncer.MockClient
    |> stub(:judge, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      allowed()
    end)

    :ok
  end

  test "issue, get, and list keys" do
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

  defp test_call(method, path, params_or_body \\ nil) do
    conn =
      conn(method, path, params_or_body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer 42")
      |> router_call()

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
