defmodule ApiKeyMgmt.Auth do
  @moduledoc """
  Module that acts upon an Auth.Context to perform authentication and authorization.
  Performs necessary RPC requests to TokenKeeper, OrgManagement and Bouncer.
  """
  alias ApiKeyMgmt.Auth.Context

  alias Plugger.Generated.Auth.{SecurityScheme, SecurityScheme.Bearer}
  alias TokenKeeper.{Authenticator, Identity}

  require Logger

  @spec authenticate(Context.t(), SecurityScheme.t(), opts :: Keyword.t()) ::
          {:allowed, Context.t()} | {:forbidden, reason :: any}
  def authenticate(context, %Bearer{token: token}, opts) do
    Logger.debug("Authenticating with context #{inspect(context)}")

    with {:ok, identity} <- get_bearer_identity(token, context.request_origin, opts),
         {:ok, context_fragments} <- get_identity_fragments(identity, opts) do
      context = %{
        context
        | external_fragments: Map.merge(context.external_fragments, context_fragments)
      }

      {:allowed, Map.put(context, :identity, identity)}
    else
      {:error, reason} -> {:forbidden, reason}
    end
  end

  @spec authorize(Context.t(), opts :: Keyword.t()) ::
          {:allowed, Context.t()}
          | :forbidden
  def authorize(context, opts) do
    resolution =
      context
      |> Context.get_fragments()
      |> Bouncer.judge(opts[:rpc_context])

    case resolution do
      {:ok, :allowed} -> {:allowed, context}
      {:ok, :forbidden} -> :forbidden
    end
  end

  ##

  @spec get_bearer_identity(token :: String.t(), request_origin :: String.t(), Keyword.t()) ::
          {:ok, Identity.t()}
          | {:error, Authenticator.error()}
  defp get_bearer_identity(token, request_origin, opts) do
    client = Authenticator.client(opts[:rpc_context])

    Logger.debug(
      "Calling token-keeper with client: #{inspect(client)} and opts: #{inspect(opts)}"
    )

    Authenticator.authenticate(client, token, request_origin)
  end

  defp get_identity_fragments(identity, opts) do
    with {:ok, additional_fragments} <- get_identity_type_fragments(identity.type, opts) do
      {:ok, Map.merge(%{"token-keeper" => identity.bouncer_fragment}, additional_fragments)}
    end
  end

  defp get_identity_type_fragments(%TokenKeeper.Identity.User{id: user_id} = user, opts) do
    Logger.debug("Calling org-management with user: #{inspect(user)} and opts: #{inspect(opts)}")

    fragment =
      case get_user_org_fragment(user_id, opts) do
        {:ok, context_fragment} -> %{"org-management" => context_fragment}
        {:error, {:user, :not_found}} -> %{}
      end

    {:ok, fragment}
  end

  defp get_identity_type_fragments(_identity, _opts) do
    {:ok, %{}}
  end

  defp get_user_org_fragment(user_id, opts) do
    OrgManagement.get_user_context(user_id, opts[:rpc_context])
  end
end
