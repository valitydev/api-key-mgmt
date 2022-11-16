defmodule Bouncer.ContextFragmentBuilderTest do
  @moduledoc """
  Tests for Bouncer.ContextFragmentBuilder helper module.
  Most tests are defined as doctests here.
  """
  use ExUnit.Case, async: true

  import Bouncer.ContextFragmentBuilder

  alias Bouncer.Context.V1.{
    ApiKeyMgmtOperation,
    Auth,
    AuthScope,
    ContextApiKeyMgmt,
    ContextFragment,
    Deployment,
    Environment,
    Requester,
    Token
  }

  alias Bouncer.Base.Entity

  alias Bouncer.Context.ContextFragment, as: BakedContextFragment
  alias Bouncer.Context.ContextFragmentType
  require ContextFragmentType

  doctest Bouncer.ContextFragmentBuilder

  test "environment should automatically populate the time" do
    %ContextFragment{env: %Environment{now: now}} = build() |> environment("my_deployment")
    refute now == nil
    assert match?({:ok, _, _}, DateTime.from_iso8601(now))
  end
end
