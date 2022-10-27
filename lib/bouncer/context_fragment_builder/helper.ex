defmodule Bouncer.ContextFragmentBuilder.Helper do
  @moduledoc """
  Helper functions to construct parts of a Bouncer context
  """
  alias Bouncer.Base.Entity

  alias Bouncer.Context.V1.{
    ApiKeyMgmtOperation,
    Auth,
    AuthScope,
    ContextApiKeyMgmt,
    Deployment,
    Environment,
    Requester,
    Token
  }

  @spec environment(iso8601_datetime :: String.t() | nil, deployment_id :: String.t()) ::
          Environment.t()
  def environment(datetime, deployment_id) do
    %Environment{
      now: datetime || now(),
      deployment: %Deployment{
        id: deployment_id
      }
    }
  end

  @spec requester(ip_address :: String.t()) :: Requester.t()
  def requester(ip_address) do
    %Requester{
      ip: ip_address
    }
  end

  @spec apikeymgmt(
          operation_id :: String.t(),
          organization :: Entity.t() | nil,
          api_key :: Entity.t() | nil
        ) ::
          ContextApiKeyMgmt.t()
  def apikeymgmt(operation_id, organization, api_key) do
    %ContextApiKeyMgmt{
      op: %ApiKeyMgmtOperation{
        id: operation_id,
        organization: organization,
        api_key: api_key
      }
    }
  end

  @spec auth(
          method :: String.t(),
          expiration :: String.t() | nil,
          token_id :: String.t(),
          scopes :: Keyword.t()
        ) ::
          Auth.t()
  def auth(method, expiration, token_id, scopes) do
    scopes = Enum.into(scopes, MapSet.new(), &auth_scope_from_keyword/1)

    %Auth{
      method: method,
      expiration: expiration,
      scope: scopes,
      token: %Token{id: token_id}
    }
  end

  defp now do
    {:ok, now} = DateTime.now("Etc/UTC")
    DateTime.to_iso8601(now)
  end

  defp auth_scope_from_keyword({:party, party_id}) do
    %AuthScope{
      party: %Entity{id: party_id}
    }
  end
end
