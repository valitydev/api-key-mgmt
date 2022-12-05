defmodule Bouncer do
  @moduledoc """
  Bouncer service client.
  """
  alias Bouncer.Client
  alias Bouncer.Context.ContextFragment, as: EncodedContextFragment

  alias Bouncer.Decisions.{
    Context,
    InvalidContext,
    InvalidRuleset,
    Resolution,
    ResolutionAllowed,
    ResolutionForbidden,
    RulesetNotFound
  }

  @type fragment() :: EncodedContextFragment.t()
  @type fragments() :: %{fragment_id() => fragment()}
  @type ctx() :: any()

  @type resolution() :: :allowed | :forbidden
  @type error() :: :ruleset_not_found | :invalid_ruleset | :invalid_context

  @typep fragment_id() :: String.t()

  @spec judge(fragments(), ctx()) :: {:ok, resolution()} | {:error, error()}
  def judge(fragments, ctx) do
    case Client.judge(fragments_to_context(fragments), ctx) do
      {:ok, judgement} -> {:ok, decode_resolution(judgement.resolution)}
      {:exception, %RulesetNotFound{}} -> {:error, :ruleset_not_found}
      {:exception, %InvalidRuleset{}} -> {:error, :invalid_ruleset}
      {:exception, %InvalidContext{}} -> {:error, :invalid_context}
    end
  end

  defp fragments_to_context(fragments) do
    fragments
    |> wrap_fragments()
  end

  defp wrap_fragments(fragments), do: %Context{fragments: fragments}

  defp decode_resolution(%Resolution{allowed: %ResolutionAllowed{}}), do: :allowed
  defp decode_resolution(%Resolution{forbidden: %ResolutionForbidden{}}), do: :forbidden
end
