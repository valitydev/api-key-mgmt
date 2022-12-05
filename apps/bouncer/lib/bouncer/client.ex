defmodule Bouncer.Client do
  @moduledoc """
  A client behaviour for the Bouncer service client.
  """
  alias Bouncer.Client.Woody
  alias Bouncer.Decisions.{Context, InvalidContext, InvalidRuleset, Judgement, RulesetNotFound}

  @callback judge(Context.t(), rpc_context :: any()) ::
              {:ok, Judgement.t()}
              | {:exception, RulesetNotFound.t() | InvalidRuleset.t() | InvalidContext.t()}

  @spec judge(Context.t(), rpc_context :: any()) ::
          {:ok, Judgement.t()}
          | {:exception, RulesetNotFound.t() | InvalidRuleset.t() | InvalidContext.t()}
  def judge(bouncer_context, ctx) do
    impl().judge(bouncer_context, ctx)
  end

  if Mix.env() == :test do
    defp impl, do: Application.get_env(:bouncer, :client_impl, Woody)
  else
    @client_mod Application.compile_env(:bouncer, :client_impl, Woody)
    defp impl, do: @client_mod
  end
end
