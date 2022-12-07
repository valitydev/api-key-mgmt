defmodule ApiKeyMgmt.Health.Router do
  @moduledoc """
  Router for the kubernetes health handles.
  """
  use Plug.Router

  alias ApiKeyMgmt.Health

  plug(:match)
  plug(:dispatch)

  get "/startup" do
    health_response(conn, Health.started?())
  end

  get "/liveness" do
    health_response(conn, Health.alive?())
  end

  get "/readiness" do
    health_response(conn, Health.ready?())
  end

  match _ do
    send_resp(conn, :not_found, "")
  end

  defp health_response(conn, true), do: send_resp(conn, :ok, "")
  defp health_response(conn, false), do: send_resp(conn, :service_unavailable, "")
end
