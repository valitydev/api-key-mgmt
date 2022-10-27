defmodule ApiKeyMgmt do
  @moduledoc """
  Main application module.
  """
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      ApiKeyMgmt.Repository,
      {Plug.Cowboy, scheme: :http, plug: ApiKeyMgmt.Router, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: ApiKeyMgmt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
