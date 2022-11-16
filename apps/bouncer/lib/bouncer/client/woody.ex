defmodule Bouncer.Client.Woody do
  @moduledoc """
  Woody implementation of Bouncer.Client
  """
  @behaviour Bouncer.Client

  alias Woody.Generated.Bouncer.Decisions.Arbiter.Client
  alias Bouncer.Decisions.{Context, InvalidContext, InvalidRuleset, Judgement, RulesetNotFound}
  alias Woody.Context, as: WoodyContext

  @spec judge(Context.t(), WoodyContext.t()) ::
          {:ok, Judgement.t()}
          | {:exception, RulesetNotFound.t() | InvalidRuleset.t() | InvalidContext.t()}
  def judge(context, woody_ctx) do
    config = Application.fetch_env!(:bouncer, __MODULE__)

    woody_ctx
    |> Client.new(config[:url], config[:opts] || [])
    |> Client.judge(config[:ruleset_id], context)
  end
end
