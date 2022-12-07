defmodule ApiKeyMgmt.Health do
  @moduledoc """
  Provides functions do determine service healthiness/readiness.
  Used mainly for kubernetes probes.
  """

  @doc """
  Used to check if the application has started
  """
  @spec started? :: boolean()
  def started? do
    true
  end

  @doc """
  Used to check if the application is available and alive.
  """
  @spec alive? :: boolean()
  def alive? do
    true
  end

  @doc """
  Used to check if the application is ready to use and serve the traffic.
  """
  @spec ready? :: boolean()
  def ready? do
    # Fetch a record from the database to see if its alive
    _key =
      ApiKeyMgmt.ApiKey
      |> Ecto.Query.first()
      |> ApiKeyMgmt.Repository.one()

    true
  rescue
    _e -> false
  end
end
