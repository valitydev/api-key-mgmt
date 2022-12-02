defmodule ApiKeyMgmt.Auth.ContextTest do
  @moduledoc """
    Tests for Auth.Context module.
  """
  use ExUnit.Case, async: true
  alias ApiKeyMgmt.Auth.Context

  test "should construct a context with a base fragment" do
    origin = "http://localhost"
    remote_ip = {127, 0, 0, 1}
    ts_now = ~U[2022-10-26T17:02:28.339227Z]
    deployment_id = "production"

    assert match?(
             %Context{
               request_origin: ^origin,
               app_fragment: %Bouncer.Context.V1.ContextFragment{
                 env: %Bouncer.Context.V1.Environment{
                   now: "2022-10-26T17:02:28.339227Z",
                   deployment: %Bouncer.Context.V1.Deployment{
                     id: ^deployment_id
                   }
                 },
                 requester: %Bouncer.Context.V1.Requester{
                   ip: "127.0.0.1"
                 }
               }
             },
             Context.new(origin, remote_ip, deployment_id, ts_now)
           )
  end

  test "should put operation context" do
    context = Context.new("", {127, 0, 0, 1}, "production")
    operation_id = "TestOperation"
    party_id = "party_id"
    api_key_id = "api_key_id"

    assert match?(
             %Context{
               app_fragment: %Bouncer.Context.V1.ContextFragment{
                 apikeymgmt: %Bouncer.Context.V1.ContextApiKeyMgmt{
                   op: %Bouncer.Context.V1.ApiKeyMgmtOperation{
                     id: ^operation_id,
                     party: %Bouncer.Base.Entity{id: ^party_id},
                     api_key: %Bouncer.Base.Entity{id: ^api_key_id}
                   }
                 }
               }
             },
             Context.put_operation(context, operation_id, party_id, api_key_id)
           )
  end

  test "should add entites to context" do
    alias TestSupport.ApiKeyManagement.Auth.TestEntity

    context = Context.new("", {127, 0, 0, 1}, "production")
    ent_id_1 = "ent_id_1"
    ent_id_2 = "ent_id_2"
    ent_1 = %TestEntity{id: ent_id_1}
    ent_2 = %TestEntity{id: ent_id_2}

    ent_set =
      MapSet.new([
        %Bouncer.Base.Entity{id: ent_id_1, type: "TestEntity"},
        %Bouncer.Base.Entity{id: ent_id_2, type: "TestEntity"}
      ])

    assert match?(
             %Context{
               app_fragment: %Bouncer.Context.V1.ContextFragment{
                 entities: ^ent_set
               }
             },
             context
             |> Context.add_operation_entity(ent_1)
             |> Context.add_operation_entity(ent_2)
           )
  end

  test "should return combined contexts with app fragment encoded" do
    context = %Context{
      request_origin: "",
      external_fragments: %{
        "token-keeper" => %Bouncer.Context.ContextFragment{type: 1},
        "org-management" => %Bouncer.Context.ContextFragment{type: 2}
      },
      app_fragment: %Bouncer.Context.V1.ContextFragment{vsn: 1}
    }

    assert match?(
             %{
               "token-keeper" => %Bouncer.Context.ContextFragment{type: 1},
               "org-management" => %Bouncer.Context.ContextFragment{type: 2},
               "api-key-mgmt" => %Bouncer.Context.ContextFragment{type: 0}
             },
             Context.get_fragments(context)
           )
  end
end
