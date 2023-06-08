defmodule ApiKeyMgmt.Auth do
  @moduledoc """
  Module that acts upon an Auth.Context to perform authentication and authorization.
  Performs necessary RPC requests to TokenKeeper, OrgManagement and Bouncer.
  """
  alias ApiKeyMgmt.Auth.Context

  alias Plugger.Generated.Auth.{SecurityScheme, SecurityScheme.Bearer}
  alias TokenKeeper.{Authenticator, Identity}

  require Logger

  @identity_prefix "user-identity."

  @spec authenticate(Context.t(), SecurityScheme.t(), opts :: Keyword.t()) ::
          {:allowed, Context.t()} | {:forbidden, reason :: any}
  def authenticate(context, %Bearer{token: token}, opts) do
    with {:ok, identity} <- get_bearer_identity(token, context.request_origin, opts),
         {:ok, opt_w_rpc_meta} <- maybe_put_identity_meta(opts, identity.type),
         {:ok, context_fragments} <- get_identity_fragments(identity, opt_w_rpc_meta) do
      context = %{
        context
        | external_fragments: Map.merge(context.external_fragments, context_fragments)
      }

      Logger.debug(fn ->
        "Identity #{inspect(identity)} with context #{inspect(context)} successfully authenticated"
      end)

      {:allowed, Map.put(context, :identity, identity)}
    else
      {:error, reason} ->
        Logger.debug(fn ->
          "Failed to authenticate token bearer with context #{inspect(context)} and reason: #{inspect(reason)}"
        end)

        {:forbidden, reason}
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

  defp maybe_put_identity_meta(opts, :unknown) do
    opts
  end

  defp maybe_put_identity_meta(opts, identity) do
    identity_meta =
      identity
      |> Map.take(~w(id realm email)a)
      |> Enum.reduce(%{}, fn
        {_k, nil}, acc -> acc
        {k, v}, acc -> Map.put_new(acc, "#{@identity_prefix}#{k}", v)
      end)

    new_opts =
      Keyword.update!(opts, :rpc_context, fn ctx ->
        Map.update(ctx, :meta, identity_meta, &Map.merge(&1, identity_meta))
      end)

    {:ok, new_opts}
  end

  @spec get_bearer_identity(token :: String.t(), request_origin :: String.t(), Keyword.t()) ::
          {:ok, Identity.t()}
          | {:error, Authenticator.error()}
  defp get_bearer_identity(token, request_origin, opts) do
    client = Authenticator.client(opts[:rpc_context])
    Authenticator.authenticate(client, token, request_origin)
  end

  defp get_identity_fragments(identity, opts) do
    with {:ok, additional_fragments} <- get_identity_type_fragments(identity.type, opts) do
      {:ok, Map.merge(%{"token-keeper" => identity.bouncer_fragment}, additional_fragments)}
    end
  end

  defp get_identity_type_fragments(%Identity.User{id: user_id} = identity, opts) do
    fragment =
      case get_user_org_fragment(user_id, opts) do
        {:ok, context_fragment} -> %{"org-management" => context_fragment}
        {:error, {:user, :not_found}} -> %{}
      end

    Logger.debug(fn ->
      "Context fragment for identity #{inspect(identity)} is #{inspect(fragment)}"
    end)

    {:ok, fragment}
  end

  defp get_identity_type_fragments(identity, _opts) do
    Logger.debug(fn -> "Context fragment for identity #{inspect(identity)} is empty" end)

    {:ok, %{}}
  end

  defp get_user_org_fragment(user_id, opts) do
    OrgManagement.get_user_context(user_id, opts[:rpc_context])
  end
end
