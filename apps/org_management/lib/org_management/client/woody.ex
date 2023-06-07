defmodule OrgManagement.Client.Woody do
  @moduledoc """
  Woody implementation of Bouncer.Client
  """
  @behaviour OrgManagement.Client

  alias Bouncer.Context.ContextFragment
  alias OrgManagement.AuthContextProvider.UserNotFound
  alias Woody.Context
  alias Woody.Generated.OrgManagement.AuthContextProvider.AuthContextProvider.Client

  require Logger

  @spec get_user_context(user_id :: String.t(), Context.t()) ::
          {:ok, ContextFragment.t()} | {:exception, UserNotFound.t()}
  def get_user_context(user_id, woody_ctx) do
    config = Application.fetch_env!(:org_management, __MODULE__)
    client = Client.new(woody_ctx, config[:url], config[:opts] || [])

    Client.get_user_context(client, user_id)
  end
end
