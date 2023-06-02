defmodule ApiKeyMgmt.Router do
  @moduledoc """
  Plug router for the application. It's only job is to forward
  requests to the codegenned Plugger router.
  """
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug :match
  plug :dispatch

  forward("/health", to: ApiKeyMgmt.Health.Router)

  forward("/apikeys/v1", to: Plugger.Generated.Router, assigns: %{handler: ApiKeyMgmt.Handler})

  if Mix.env() == :dev do
    forward("/sent_emails", to: Bamboo.SentEmailViewerPlug)
  end

  match _ do
    send_resp(conn, :not_found, "")
  end
end
