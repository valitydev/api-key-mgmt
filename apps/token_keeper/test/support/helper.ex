defmodule TestSupport.TokenKeeper.Helper do
  @moduledoc """
  Helper functions to use with tests related to TokenKeeper
  """
  alias Bouncer.Context.ContextFragment
  alias TokenKeeper.Keeper.{AuthData, AuthDataStatus}

  @spec make_authdata(
          id :: String.t() | nil,
          metadata :: map(),
          ContextFragment.t(),
          status :: non_neg_integer()
        ) :: AuthData.t()
  def make_authdata(
        id \\ nil,
        metadata \\ %{},
        context \\ test_context(),
        status \\ status_active()
      ) do
    %AuthData{
      id: id,
      status: status,
      context: context,
      metadata: metadata
    }
  end

  defp status_active do
    require AuthDataStatus
    AuthDataStatus.active()
  end

  defp test_context do
    import Bouncer.ContextFragmentBuilder

    build() |> bake()
  end
end
