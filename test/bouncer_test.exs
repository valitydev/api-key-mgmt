defmodule BouncerTest do
  @moduledoc """
  Contains tests for Bouncer client library. Keep it client implementation agnostic.
  """
  use ExUnit.Case, async: true
  import Mox

  alias Bouncer.Context.V1.ContextFragment
  alias Bouncer.Decisions.{InvalidContext, InvalidRuleset, RulesetNotFound}
  alias TestSupport.Bouncer.Helper

  setup :verify_on_exit!

  test "should resolve to allowed" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      allowed()
    end)

    assert Bouncer.judge(test_fragments(), %{}) == {:ok, :allowed}
  end

  test "should resolve to forbidden" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      import TestSupport.Bouncer.Helper
      forbidden()
    end)

    assert Bouncer.judge(test_fragments(), %{}) == {:ok, :forbidden}
  end

  test "should return an error with :ruleset_not_found reason" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      {:exception, RulesetNotFound.new()}
    end)

    assert Bouncer.judge(test_fragments(), %{}) == {:error, :ruleset_not_found}
  end

  test "should return an error with :invalid_ruleset reason" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      {:exception, InvalidRuleset.new()}
    end)

    assert Bouncer.judge(test_fragments(), %{}) == {:error, :invalid_ruleset}
  end

  test "should return an error with :invalid_context reason" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      {:exception, InvalidContext.new()}
    end)

    assert Bouncer.judge(test_fragments(), %{}) == {:error, :invalid_context}
  end

  defp test_fragments do
    %{
      "test" => ContextFragment.new()
    }
  end
end
