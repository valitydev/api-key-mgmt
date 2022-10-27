defmodule TokenKeeper.IdentityTest do
  @moduledoc """
  Tests for TokenKeeper.Identity module
  """
  use ExUnit.Case, async: true

  alias Bouncer.Context.ContextFragment
  alias TokenKeeper.Identity
  alias TokenKeeper.Identity.{Party, User}
  alias TokenKeeper.Keeper.AuthData

  test "should fail to interpret any identity type" do
    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        "random" => "lmao"
      }
    }

    assert match?(%Identity{type: :unknown}, Identity.from_authdata(authdata))
  end

  test "should fail to decide on identity type with conflicting data" do
    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        "party.id" => "42",
        "user.id" => "walter"
      }
    }

    assert match?(%Identity{type: :unknown}, Identity.from_authdata(authdata))
  end

  test "should interpret User identity type" do
    user_id = "walter"

    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        "user.id" => user_id
      }
    }

    assert match?(%Identity{type: %User{id: ^user_id}}, Identity.from_authdata(authdata))
  end

  test "should interpret User identity type with a mapping" do
    user_id = "walter"

    mapping = %{
      user_id: "my.user.id"
    }

    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        mapping[:user_id] => user_id
      }
    }

    assert match?(
             %Identity{type: %User{id: ^user_id}},
             Identity.from_authdata(authdata, metadata_mapping: mapping)
           )
  end

  test "should interpret User identity type with all the additional fields" do
    user_id = "walter"
    user_email = "example@test"
    user_realm = "otherworldly"

    mapping = %{
      user_id: "my.user.id",
      user_email: "my.user.email",
      user_realm: "my.user.realm"
    }

    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        mapping[:user_id] => user_id,
        mapping[:user_email] => user_email,
        mapping[:user_realm] => user_realm
      }
    }

    assert Identity.from_authdata(authdata, metadata_mapping: mapping) == %Identity{
             bouncer_fragment: %ContextFragment{},
             type: %User{id: user_id, email: user_email, realm: user_realm}
           }
  end

  test "should interpret Party identity type" do
    party_id = "42"

    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        "party.id" => party_id
      }
    }

    assert match?(%Identity{type: %Party{id: ^party_id}}, Identity.from_authdata(authdata))
  end

  test "should interpret Party identity type with a mapping" do
    party_id = "42"

    mapping = %{
      party_id: "my.party.id"
    }

    authdata = %AuthData{
      context: %ContextFragment{},
      metadata: %{
        mapping[:party_id] => party_id
      }
    }

    assert match?(
             %Identity{type: %Party{id: ^party_id}},
             Identity.from_authdata(authdata, metadata_mapping: mapping)
           )
  end

  test "should produce correct metadata for User identity" do
    user_id = "walter"
    user_email = "example@test"
    user_realm = "otherworldly"

    mapping = %{
      user_id: "my.user.id",
      user_email: "my.user.email",
      user_realm: "my.user.realm"
    }

    identity = %Identity{
      bouncer_fragment: %ContextFragment{},
      type: %User{id: user_id, email: user_email, realm: user_realm}
    }

    assert Identity.to_context_metadata(identity, metadata_mapping: mapping) ==
             {%ContextFragment{},
              %{
                mapping[:user_id] => user_id,
                mapping[:user_email] => user_email,
                mapping[:user_realm] => user_realm
              }}
  end

  test "should not produce more metadata then exists" do
    user_id = "walter"

    mapping = %{
      user_id: "my.user.id",
      user_email: "my.user.email",
      user_realm: "my.user.realm"
    }

    identity = %Identity{
      bouncer_fragment: %ContextFragment{},
      type: %User{id: user_id}
    }

    assert Identity.to_context_metadata(identity, metadata_mapping: mapping) ==
             {%ContextFragment{},
              %{
                mapping[:user_id] => user_id
              }}
  end

  test "should produce correct metadata for Party identity" do
    party_id = "42"

    mapping = %{
      party_id: "my.party.id"
    }

    identity = %Identity{
      bouncer_fragment: %ContextFragment{},
      type: %Party{id: party_id}
    }

    assert Identity.to_context_metadata(identity, metadata_mapping: mapping) ==
             {%ContextFragment{},
              %{
                mapping[:party_id] => party_id
              }}
  end
end
