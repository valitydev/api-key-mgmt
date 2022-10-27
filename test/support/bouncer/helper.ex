defmodule TestSupport.Bouncer.Helper do
  @moduledoc """
  Helper functions to use with tests related to Bouncer
  """
  alias Bouncer.Base.Entity
  alias Bouncer.Context.ContextFragment, as: EncodedContextFragment

  alias Bouncer.Context.V1.{
    ApiKeyMgmtOperation,
    Auth,
    AuthScope,
    ContextApiKeyMgmt,
    ContextFragment
  }

  alias Bouncer.Decisions.{Context, Judgement, Resolution, ResolutionAllowed, ResolutionForbidden}

  def assert_context(%Context{fragments: fragments} = context, assert_fun) do
    _ = assert_fun.(decode_fragments(fragments))
    context
  end

  def assert_fragment(%EncodedContextFragment{} = fragment, assert_fun) do
    _ = assert_fun.(decode_fragment(fragment))
    fragment
  end

  def assert_apikeymgmt(fragment, operation_id, party_id \\ nil, api_key_id \\ nil) do
    api_key = if(api_key_id, do: %Entity{id: api_key_id})
    party = if(party_id, do: %Entity{id: party_id})

    case fragment do
      %ContextFragment{
        apikeymgmt: %ContextApiKeyMgmt{
          op: %ApiKeyMgmtOperation{
            id: ^operation_id,
            organization: ^party,
            api_key: ^api_key
          }
        }
      } ->
        fragment

      _ ->
        raise "`apikeymgmt` assertion failed, fragment #{inspect(fragment)} does not match"
    end
  end

  def assert_entity(%ContextFragment{entities: entities} = fragment, entity) do
    unless Enum.member?(entities, entity) do
      raise "`entity` assertion failed, no #{inspect(entity)} in #{inspect(entities)}"
    end

    fragment
  end

  def assert_auth(fragment, method, expiration, token_id, scopes) do
    scopes = Enum.into(scopes, MapSet.new(), &auth_scope_from_keyword/1)

    case fragment do
      %ContextFragment{
        auth: %Auth{
          method: ^method,
          expiration: ^expiration,
          scope: ^scopes,
          token: %Bouncer.Context.V1.Token{id: ^token_id}
        }
      } ->
        fragment

      _ ->
        raise "`auth` assertion failed, fragment #{inspect(fragment)} does not match"
    end
  end

  def allowed do
    {:ok,
     %Judgement{
       resolution: %Resolution{
         allowed: %ResolutionAllowed{}
       }
     }}
  end

  def forbidden do
    {:ok,
     %Judgement{
       resolution: %Resolution{
         forbidden: %ResolutionForbidden{}
       }
     }}
  end

  defp decode_fragments(fragments) do
    fragments
    |> Enum.into(%{}, fn {k, v} -> {k, decode_fragment(v)} end)
  end

  defp decode_fragment(%EncodedContextFragment{
         content: content
       }) do
    ## ...
    {struct, ""} = ContextFragment.deserialize(:erlang.iolist_to_binary(content))
    struct
  end

  defp auth_scope_from_keyword({:party, party_id}) do
    %AuthScope{
      party: %Entity{id: party_id}
    }
  end
end
