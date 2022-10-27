defmodule ApiKeyMgmt.Router do
  @moduledoc """
  Plug router for the application. It's only job is to forward
  requests to the codegenned Plugger router.
  """
  use Plug.Router

  plug(Plug.Logger)

  plug(:match)
  plug(:dispatch)

  forward("/", to: Plugger.Generated.Router, assigns: %{handler: ApiKeyMgmt.Handler})
end
