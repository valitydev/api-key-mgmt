defmodule OrgManagement.Client do
  @moduledoc """
  A client behaviour for the OrgManagement service client.
  """
  alias Bouncer.Context.ContextFragment
  alias OrgManagement.AuthContextProvider.UserNotFound
  alias OrgManagement.Client.Woody

  @callback get_user_context(user_id :: String.t(), rpc_context :: any()) ::
              {:ok, ContextFragment.t()} | {:exception, UserNotFound.t()}

  @spec get_user_context(user_id :: String.t(), rpc_context :: any()) ::
          {:ok, ContextFragment.t()} | {:exception, UserNotFound.t()}
  def get_user_context(user_id, ctx) do
    impl().get_user_context(user_id, ctx)
  end

  if Mix.env() == :test do
    defp impl, do: Application.get_env(:api_key_mgmt, :org_management_impl, Woody)
  else
    @client_mod Application.compile_env(:api_key_mgmt, :org_management_impl, Woody)
    defp impl, do: @client_mod
  end
end
