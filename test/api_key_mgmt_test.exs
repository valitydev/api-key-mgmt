defmodule ApiKeyMgmtTest do
  @moduledoc """
  External app tests
  """

  ## FIXME: This test suite is kinda pointless

  use ExUnit.Case, async: true
  use Plug.Test

  import Mox

  setup do
    alias Ecto.Adapters.SQL.Sandbox
    :ok = Sandbox.checkout(ApiKeyMgmt.Repository)

    TokenKeeper.Authenticator.MockClient
    |> stub(:new, fn ctx -> ctx end)

    TokenKeeper.Authority.MockClient
    |> stub(:new, fn _authority, ctx -> ctx end)

    :ok
  end

  test "test finch" do
    TokenKeeper.Authenticator.MockClient
    |> expect(:authenticate, fn _client, _token, _origin ->
      import TestSupport.TokenKeeper.Helper
      {:ok, make_authdata()}
    end)

    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      allowed()
    end)

    TokenKeeper.Authority.MockClient
    |> expect(:create, fn _client, id, context_fragment, metadata ->
      import TestSupport.TokenKeeper.Helper
      {:ok, make_authdata(id, :active, context_fragment, metadata)}
    end)

    # assert false ==
    #         call(:post, "http://localhost:8080/parties/1/api-keys", %{"name" => "name"} |> Jason.encode!())

    # assert false ==
    #         call(:get, "http://localhost:8080/parties/1/api-keys/1")
  end

  # defp call(method, path, params_or_body \\ nil) do
  #   conn =
  #     conn(method, path, params_or_body)
  #     |> ApiKeyMgmt.Router.call(ApiKeyMgmt.Router.init([]))

  #   resp_body =
  #     case conn.resp_body do
  #       "" -> nil
  #       body -> body |> Jason.decode!(keys: :atoms!)
  #     end

  #   {conn.status, resp_body}
  # end
end
