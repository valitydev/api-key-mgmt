defmodule ApiKeyMgmt.AuthTest do
  @moduledoc """
  Tests for Auth module.
  """
  use ExUnit.Case, async: true

  import Mox

  alias ApiKeyMgmt.Auth
  alias Bouncer.Context.V1.ContextFragment
  alias OrgManagement.AuthContextProvider.UserNotFound
  alias Plugger.Generated.Auth.SecurityScheme.Bearer
  alias TokenKeeper.Authenticator
  alias TokenKeeper.Keeper.{AuthData, AuthDataNotFound}

  setup :verify_on_exit!

  test "should authenticate a bearer token and gather user metadata context" do
    Authenticator.MockClient
    |> expect(:new, fn ctx -> ctx end)
    |> expect(:authenticate, fn _client, "42", _origin ->
      {:ok,
       %AuthData{
         context: %ContextFragment{vsn: 1},
         metadata: %{
           "user.id" => "my_user"
         }
       }}
    end)

    OrgManagement.MockClient
    |> expect(:get_user_context, fn "my_user", _ctx ->
      {:ok, %ContextFragment{vsn: 2}}
    end)

    auth_result =
      Auth.Context.new("", {0, 0, 0, 0})
      |> Auth.authenticate(%Bearer{token: "42"}, rpc_context: %{})

    assert match?({:allowed, _}, auth_result)

    {:allowed, context} = auth_result

    assert match?(
             %{
               "token-keeper" => %ContextFragment{vsn: 1},
               "org-management" => %ContextFragment{vsn: 2}
             },
             context.external_fragments
           )
  end

  test "should authenticate a bearer token but fail gathering user context" do
    Authenticator.MockClient
    |> expect(:new, fn ctx -> ctx end)
    |> expect(:authenticate, fn _client, "42", _origin ->
      {:ok,
       %AuthData{
         context: %ContextFragment{vsn: 1},
         metadata: %{
           "user.id" => "my_user"
         }
       }}
    end)

    OrgManagement.MockClient
    |> expect(:get_user_context, fn "my_user", _ctx ->
      {:exception, %UserNotFound{}}
    end)

    assert {:forbidden, {:org_management_error, {:user, :not_found}}} =
             Auth.Context.new("", {0, 0, 0, 0})
             |> Auth.authenticate(%Bearer{token: "42"}, rpc_context: %{})
  end

  test "should authenticate a bearer token and gather party metadata context" do
    Authenticator.MockClient
    |> expect(:new, fn ctx -> ctx end)
    |> expect(:authenticate, fn _client, "42", _origin ->
      {:ok,
       %AuthData{
         context: %ContextFragment{vsn: 1},
         metadata: %{
           "party.id" => "my_party"
         }
       }}
    end)

    auth_result =
      Auth.Context.new("", {0, 0, 0, 0})
      |> Auth.authenticate(%Bearer{token: "42"}, rpc_context: %{})

    assert match?({:allowed, _}, auth_result)

    {:allowed, context} = auth_result

    assert match?(
             %{
               "token-keeper" => %ContextFragment{vsn: 1}
             },
             context.external_fragments
           )
  end

  test "should fail to authenticate a bearer token" do
    Authenticator.MockClient
    |> expect(:new, fn ctx -> ctx end)
    |> expect(:authenticate, fn _client, "42", _origin ->
      {:exception, %AuthDataNotFound{}}
    end)

    assert {:forbidden, {:token_keeper_error, {:auth_data, :not_found}}} =
             Auth.Context.new("", {0, 0, 0, 0})
             |> Auth.authenticate(%Bearer{token: "42"}, rpc_context: %{})
  end

  test "should authorize an operation and allow it" do
    Bouncer.MockClient
    |> expect(:judge, fn context, _ctx ->
      assert match?(
               %Bouncer.Decisions.Context{
                 fragments: %{
                   "token-keeper" => _,
                   "api-key-mgmt" => _
                 }
               },
               context
             )

      {:ok,
       %Bouncer.Decisions.Judgement{
         resolution: %Bouncer.Decisions.Resolution{
           allowed: %Bouncer.Decisions.ResolutionAllowed{}
         }
       }}
    end)

    context = %{
      Auth.Context.new("", {0, 0, 0, 0})
      | external_fragments: %{
          "token-keeper" => %Bouncer.Context.ContextFragment{}
        }
    }

    assert match?(
             {:allowed, _},
             context
             |> Auth.Context.put_operation("TestOperation")
             |> Auth.authorize(rpc_context: %{})
           )
  end

  test "should authorize an operation and forbit it" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      {:ok,
       %Bouncer.Decisions.Judgement{
         resolution: %Bouncer.Decisions.Resolution{
           forbidden: %Bouncer.Decisions.ResolutionForbidden{}
         }
       }}
    end)

    assert {:forbidden, :bouncer_forbids_operation} ==
             Auth.Context.new("", {0, 0, 0, 0})
             |> Auth.authorize(rpc_context: %{})
  end

  test "should fail to authorize an operation" do
    Bouncer.MockClient
    |> expect(:judge, fn _context, _ctx ->
      {:exception, %Bouncer.Decisions.InvalidRuleset{}}
    end)

    assert {:forbidden, {:bouncer_error, :invalid_ruleset}} ==
             Auth.Context.new("", {0, 0, 0, 0})
             |> Auth.authorize(rpc_context: %{})
  end
end
