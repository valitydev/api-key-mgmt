defmodule ApiKeyMgmt do
  @moduledoc """
  Main application module.
  """
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      ApiKeyMgmt.Repository,
      {Plug.Cowboy, scheme: :http, plug: ApiKeyMgmt.Router, options: get_cowboy_opts()}
    ]

    opts = [strategy: :one_for_one, name: ApiKeyMgmt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_cowboy_opts do
    Application.get_env(:api_key_mgmt, Plug.Cowboy, default_cowboy_opts())
  end

  defp default_cowboy_opts, do: [port: 8080]
end
