defmodule Bouncer.Client.WoodyTest do
  @moduledoc """
  Tests for Woody implementation of Bouncer.Client behaviour.
  """
  # Can't run async mode when relying on app env
  use ExUnit.Case, async: false

  alias Bouncer.Client.Woody, as: Client
  alias Woody.Generated.Bouncer.Decisions.Arbiter, as: Service
  alias Woody.Server.Http, as: Server

  defmodule MockHandler do
    @moduledoc false

    @behaviour Service.Handler

    def new(http_path, fun, options \\ []) do
      Service.Handler.new({__MODULE__, handler_fun: fun}, http_path, options)
    end

    @spec judge(
            ruleset :: String.t(),
            ctx :: Bouncer.Decisions.Context.t(),
            ctx :: Woody.Context.t(),
            hdlopts :: Handler.hdlopts()
          ) ::
            {:ok, Bouncer.Decisions.Judgement.t()}
            | {:error, Bouncer.Decisions.RulesetNotFound.t()}
            | {:error, Bouncer.Decisions.InvalidRuleset.t()}
            | {:error, Bouncer.Decisions.InvalidContext.t()}
    @impl true
    def judge(ruleset, context, _ctx, hdlopts) do
      hdlopts[:handler_fun].(ruleset, context)
    end
  end

  test "should reply ok" do
    alias TestSupport.Bouncer.Helper

    mock_woody(fn %Bouncer.Decisions.Context{fragments: %{}} ->
      Helper.allowed()
    end)

    assert Helper.allowed() ==
             Client.judge(%Bouncer.Decisions.Context{fragments: %{}}, Woody.Context.new())
  end

  test "should reply with an exception" do
    mock_woody(fn %Bouncer.Decisions.Context{fragments: %{}} ->
      {:error, %Bouncer.Decisions.RulesetNotFound{}}
    end)

    assert {:exception, %Bouncer.Decisions.RulesetNotFound{}} ==
             Client.judge(%Bouncer.Decisions.Context{fragments: %{}}, Woody.Context.new())
  end

  defp mock_woody(handler_fn) do
    ruleset_id = "test_ruleset"

    handler_fn = fn ^ruleset_id, context ->
      handler_fn.(context)
    end

    start_supervised!(
      Server.child_spec(
        __MODULE__,
        Server.Endpoint.loopback(),
        MockHandler.new("/arbiter", handler_fn, event_handler: Woody.EventHandler.Default)
      )
    )

    endpoint = Server.endpoint(__MODULE__)

    Application.put_env(:api_key_mgmt, :bouncer,
      url: "http://#{endpoint}/arbiter",
      ruleset_id: ruleset_id
    )

    :ok
  end
end
