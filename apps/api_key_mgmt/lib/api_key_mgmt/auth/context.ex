defmodule ApiKeyMgmt.Auth.Context do
  @moduledoc """
  A struct containing information about the current authentication and authorization context.

  In handler code, please use `put_operation/4` and `add_operation_entity/2` to
  add information needed to perform authorization.
  """
  alias ApiKeyMgmt.Auth.BouncerEntity

  alias Bouncer.Context.V1.ContextFragment

  @fragment_id "api-key-mgmt"

  @enforce_keys [:request_origin, :app_fragment]
  defstruct external_fragments: %{}, app_fragment: nil, request_origin: nil, identity: nil

  @type t() :: %__MODULE__{
          request_origin: String.t() | nil,
          external_fragments: Bouncer.fragments(),
          app_fragment: ContextFragment.t(),
          identity: TokenKeeper.Identity.t() | nil
        }

  @spec new(
          request_origin :: String.t() | nil,
          requester_ip :: :inet.ip_address(),
          deployment_id :: String.t(),
          ts_now :: DateTime.t() | nil
        ) :: t()
  def new(request_origin, requester_ip, deployment_id, ts_now \\ nil) do
    %__MODULE__{
      request_origin: request_origin,
      app_fragment: build_fragment_base(requester_ip, ts_now, deployment_id)
    }
  end

  @spec put_operation(
          t(),
          operation_id :: String.t(),
          party_id :: String.t() | nil,
          api_key_id :: String.t() | nil
        ) :: t()
  def put_operation(context, operation_id, party_id \\ nil, api_key_id \\ nil) do
    alias Bouncer.Base.Entity
    import Bouncer.ContextFragmentBuilder

    party = if(party_id, do: %Entity{id: party_id})
    api_key = if(api_key_id, do: %Entity{id: api_key_id})

    app_fragment = apikeymgmt(context.app_fragment, operation_id, party, api_key)

    %{context | app_fragment: app_fragment}
  end

  @spec add_operation_entity(t(), BouncerEntity.t()) :: t()
  def add_operation_entity(context, entity) do
    import Bouncer.ContextFragmentBuilder

    app_fragment = add_entity(context.app_fragment, BouncerEntity.to_bouncer_entity(entity))

    %{context | app_fragment: app_fragment}
  end

  @spec get_fragments(t()) :: Bouncer.fragments()
  def get_fragments(context) do
    import Bouncer.ContextFragmentBuilder

    baked_app_fragment = bake(context.app_fragment)

    Map.merge(context.external_fragments, %{@fragment_id => baked_app_fragment})
  end

  ##

  defp build_fragment_base(requester_ip, ts_now, deployment_id) do
    import Bouncer.ContextFragmentBuilder

    requester_ip =
      requester_ip
      |> :inet.ntoa()
      |> List.to_string()

    build()
    |> environment(ts_now, deployment_id)
    |> requester(requester_ip)
  end
end
