defmodule OrgManagement.Client.WoodyTest do
  @moduledoc """
  Tests for Woody implementation of OrgManagement.Client behaviour.
  """
  # Can't run async mode when relying on app env
  use ExUnit.Case, async: false

  alias OrgManagement.Client.Woody, as: Client
  alias Woody.Generated.OrgManagement.AuthContextProvider.AuthContextProvider, as: Service
  alias Woody.Server.Http, as: Server

  defmodule MockHandler do
    @moduledoc false

    @behaviour Service.Handler

    @spec new(http_path :: String.t(), fun(), options :: Keyword.t()) :: Service.Handler.t()
    def new(http_path, fun, options \\ []) do
      Service.Handler.new({__MODULE__, handler_fun: fun}, http_path, options)
    end

    @spec get_user_context(
            id :: String.t(),
            ctx :: Woody.Context.t(),
            hdlops :: Handler.hdlopts()
          ) ::
            {:ok, Bouncer.Context.ContextFragment.t()}
            | {:error, OrgManagement.AuthContextProvider.UserNotFound.t()}
    @impl Service.Handler
    def get_user_context(id, _ctx, hdlopts) do
      hdlopts[:handler_fun].(id)
    end
  end

  test "should reply ok" do
    alias Bouncer.Context.ContextFragmentType
    require ContextFragmentType

    user_id = "test_user"

    mock_woody(fn ^user_id ->
      {:ok,
       %Bouncer.Context.ContextFragment{
         type: ContextFragmentType.v1_thrift_binary(),
         content: <<>>
       }}
    end)

    assert {:ok,
            %Bouncer.Context.ContextFragment{
              type: ContextFragmentType.v1_thrift_binary(),
              content: <<>>
            }} ==
             Client.get_user_context(user_id, Woody.Context.new())
  end

  test "should reply with an exception" do
    user_id = "test_user"

    mock_woody(fn ^user_id ->
      {:error, %OrgManagement.AuthContextProvider.UserNotFound{}}
    end)

    assert {:exception, %OrgManagement.AuthContextProvider.UserNotFound{}} ==
             Client.get_user_context(user_id, Woody.Context.new())
  end

  defp mock_woody(handler_fn) do
    start_supervised!(
      Server.child_spec(
        __MODULE__,
        Server.Endpoint.loopback(),
        MockHandler.new("/user_context", handler_fn, event_handler: Woody.EventHandler.Default)
      )
    )

    endpoint = Server.endpoint(__MODULE__)

    Application.put_env(:org_management, OrgManagement.Client.Woody,
      url: "http://#{endpoint}/user_context"
    )

    :ok
  end
end
