defmodule ApiKeyMgmt.Handler do
  @moduledoc """
  Core logic of the service.
  """
  @behaviour Plugger.Generated.Handler
  alias ApiKeyMgmt.{ApiKeyRepository, Auth}
  alias Plugger.Generated.Auth.SecurityScheme

  alias Plugger.Generated.Response.{
    Forbidden,
    GetApiKeyOk,
    IssueApiKeyOk,
    ListApiKeysOk,
    NotFound,
    RevokeApiKeyNoContent
  }

  alias TokenKeeper.Authority

  defmodule Context do
    @moduledoc """
    Context for the currently handled operation
    """
    alias ApiKeyMgmt.Auth.Context, as: AuthContext
    alias Woody.Context, as: RpcContext

    @enforce_keys [:rpc, :auth]
    defstruct [:rpc, :auth]

    @type t :: %__MODULE__{
            rpc: RpcContext.t(),
            auth: AuthContext.t()
          }

    @spec new(conn :: Plug.Conn.t()) :: t()
    def new(conn) do
      request_origin =
        case List.keyfind(conn.req_headers, "origin", 0) do
          {"origin", origin} -> origin
          _notfound -> nil
        end

      %__MODULE__{
        rpc: RpcContext.new(),
        auth: AuthContext.new(request_origin, conn.remote_ip)
      }
    end
  end

  @spec __init__(conn :: Plug.Conn.t()) :: Context.t()
  def __init__(conn) do
    Context.new(conn)
  end

  @spec __authenticate__(SecurityScheme.t(), Context.t()) ::
          {:allow, Context.t()} | :deny
  def __authenticate__(security_scheme, ctx) do
    case Auth.authenticate(ctx.auth, security_scheme, rpc_context: ctx.rpc) do
      {:allowed, auth_context} ->
        {:allow, %{ctx | auth: auth_context}}

      {:forbidden, _reason} ->
        :deny
    end
  end

  @spec get_api_key(party_id :: String.t(), api_key_id :: String.t(), Context.t()) ::
          GetApiKeyOk.t() | NotFound.t() | Forbidden.t()
  def get_api_key(party_id, api_key_id, ctx) do
    with {:ok, api_key} <- ApiKeyRepository.get(api_key_id),
         {:allowed, _} <-
           ctx.auth
           |> Auth.Context.put_operation("GetApiKey", party_id, api_key_id)
           |> Auth.Context.add_operation_entity(api_key)
           |> Auth.authorize(rpc_context: ctx.rpc) do
      %GetApiKeyOk{content: encode_api_key(api_key)}
    else
      {:error, :not_found} -> %NotFound{}
      {:forbidden, _} -> %Forbidden{}
    end
  end

  @spec issue_api_key(party_id :: String.t(), api_key :: map(), Context.t()) ::
          IssueApiKeyOk.t() | NotFound.t() | Forbidden.t()
  def issue_api_key(party_id, api_key, ctx) do
    import Bouncer.ContextFragmentBuilder

    token_id = Base.url_encode64(:snowflake.new(), padding: false)

    identity = %TokenKeeper.Identity{
      type: %TokenKeeper.Identity.Party{
        id: party_id
      },
      bouncer_fragment:
        build()
        |> auth("ApiKeyToken", nil, token_id, party: party_id)
        |> bake()
    }

    case ctx.auth
         |> Auth.Context.put_operation("IssueApiKey", party_id)
         |> Auth.authorize(rpc_context: ctx.rpc) do
      {:allowed, _} ->
        {:ok, authdata} =
          get_autority_id()
          |> Authority.client(ctx.rpc)
          |> Authority.create(token_id, identity)

        {:ok, api_key} = ApiKeyRepository.issue(token_id, party_id, api_key.name, authdata.token)

        %IssueApiKeyOk{content: encode_api_key(api_key)}

      {:forbidden, _} ->
        %Forbidden{}
    end
  end

  @spec list_api_keys(party_id :: String.t(), query :: Keyword.t(), Context.t()) ::
          ListApiKeysOk.t() | NotFound.t() | Forbidden.t()
  def list_api_keys(party_id, query, ctx) do
    list_opts = if(query[:status], do: [status_filter: query[:status]], else: [])

    with {:ok, results} <- ApiKeyRepository.list(party_id, list_opts),
         {:allowed, _} <-
           ctx.auth
           |> Auth.Context.put_operation("ListApiKeys", party_id)
           |> Auth.authorize(rpc_context: ctx.rpc) do
      results = results |> Enum.map(&encode_api_key/1) |> Enum.sort()
      %ListApiKeysOk{content: %{"results" => results}}
    else
      {:error, :not_found} -> %NotFound{}
      {:forbidden, _} -> %Forbidden{}
    end
  end

  @spec revoke_api_key(
          party_id :: String.t(),
          api_key_id :: String.t(),
          body :: String.t(),
          Context.t()
        ) :: RevokeApiKeyNoContent.t() | NotFound.t() | Forbidden.t()
  def revoke_api_key(party_id, api_key_id, "Revoked", ctx) do
    with {:ok, api_key} <- ApiKeyRepository.get(api_key_id),
         {:allowed, _} <-
           ctx.auth
           |> Auth.Context.put_operation("RevokeApiKey", party_id, api_key_id)
           |> Auth.Context.add_operation_entity(api_key)
           |> Auth.authorize(rpc_context: ctx.rpc) do
      :ok =
        get_autority_id()
        |> Authority.client(ctx.rpc)
        |> Authority.revoke(api_key.id)

      {:ok, _} = ApiKeyRepository.revoke(api_key)
      %RevokeApiKeyNoContent{}
    else
      {:error, :not_found} -> %NotFound{}
      {:forbidden, _} -> %Forbidden{}
    end
  end

  defp get_autority_id do
    # TODO: Research ways to make it a code option at this level, rather than doing an env fetch
    conf = Application.fetch_env!(:api_key_mgmt, __MODULE__)
    conf[:authority_id] || raise "No authority_id configured for #{__MODULE__}!"
  end

  # TODO: This is a good candidate for protocol use, but Plugger validation mechanics need to be fleshed out first
  defp encode_api_key(api_key) do
    %{
      "id" => api_key.id,
      "name" => api_key.name,
      "status" => api_key.status,
      "createdAt" => api_key.inserted_at,
      "accessToken" => api_key.access_token,
      "metadata" => api_key.metadata
    }
    |> Map.reject(fn {_, v} -> v == nil end)
  end
end
