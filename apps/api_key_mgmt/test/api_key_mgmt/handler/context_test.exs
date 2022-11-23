defmodule ApiKeyMgmt.Handler.ContextTest do
  @moduledoc """
  Tests for service handler context.
  """
  use ExUnit.Case, async: true
  alias ApiKeyMgmt.Auth.Context, as: AuthContext
  alias ApiKeyMgmt.Handler.Context

  test "should correctly create new context from connection data" do
    use Plug.Test
    import Plug.Conn

    origin = "http://localhost"
    remote_ip = {1, 3, 3, 7}
    ts_now = ~U[2022-10-26T17:02:28.339227Z]
    deployment = "deployment"

    conn =
      conn(:get, "/")
      |> put_req_header("origin", origin)
      |> Map.replace!(:remote_ip, remote_ip)

    target_context = AuthContext.new(origin, remote_ip, deployment, ts_now)

    assert match?(%Context{auth: ^target_context}, Context.new(conn, deployment, ts_now))
  end
end
