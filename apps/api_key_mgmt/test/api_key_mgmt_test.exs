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
      {:ok, make_authdata(id, :active, context_fragment, metadata)}
    end)

    Bouncer.MockClient
    |> stub(:judge, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      allowed()
    end)

    :ok
  end

  test "issue, get, and list keys" do
    # TODO: all the readOnly parameters are actually required because
    # https://github.com/open-api-spex/open_api_spex/issues/499
    issue_body = %{
      "name" => "my_cool_api_key"
    }

    assert false ==
             test_call(
               :post,
               "http://localhost:8080/parties/mypartyid/api-keys",
               issue_body |> Jason.encode!()
             )

    assert false ==
             test_call(:get, "http://localhost:8080/parties/mypartyid/api-keys")
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
end
