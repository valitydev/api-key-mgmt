defmodule OrgManagement do
  @moduledoc """
  OrgManagement service client.
  """
  alias Bouncer.Context.ContextFragment
  alias OrgManagement.AuthContextProvider.UserNotFound
  alias OrgManagement.Client

  @type error() :: {:user, :not_found}

  @spec get_user_context(user_id :: String.t(), ctx :: any()) ::
          {:ok, ContextFragment.t()} | {:error, error()}
  def get_user_context(user_id, ctx) do
    case Client.get_user_context(user_id, ctx) do
      {:ok, _} = ok -> ok
      {:exception, %UserNotFound{}} -> {:error, {:user, :not_found}}
    end
  end
end
