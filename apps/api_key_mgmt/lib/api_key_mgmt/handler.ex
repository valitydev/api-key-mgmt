defmodule ApiKeyMgmt.Handler do
  @moduledoc """
  Core logic of the service.
  """
  @behaviour Plugger.Generated.Handler
  alias ApiKeyMgmt.{ApiKey, ApiKeyRepository, Auth}
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

  @default_deployment_id "Production"

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

    @spec new(conn :: Plug.Conn.t(), deployment_id :: String.t(), ts_now :: DateTime.t() | nil) ::
            t()
    def new(conn, deployment_id, ts_now \\ nil) do
      request_origin =
        case List.keyfind(conn.req_headers, "origin", 0) do
          {"origin", origin} -> origin
          _notfound -> nil
        end

      %__MODULE__{
        rpc: RpcContext.new(),
        auth: AuthContext.new(request_origin, conn.remote_ip, deployment_id, ts_now)
      }
    end
  end

  @spec __init__(conn :: Plug.Conn.t()) :: Context.t()
  def __init__(conn) do
    Context.new(conn, get_deployment_id())
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
      :forbidden -> %Forbidden{}
    end
  end

  @spec issue_api_key(party_id :: String.t(), api_key :: map(), Context.t()) ::
          IssueApiKeyOk.t() | NotFound.t() | Forbidden.t()
  def issue_api_key(party_id, api_key, ctx) do
    authdata_id = Base.url_encode64(:snowflake.new(), padding: false)

    identity = %TokenKeeper.Identity{
      type: %TokenKeeper.Identity.Party{
        id: party_id
      }
    }

    case ctx.auth
         |> Auth.Context.put_operation("IssueApiKey", party_id)
         |> Auth.authorize(rpc_context: ctx.rpc) do
      {:allowed, _} ->
        {:ok, authdata} =
          get_authority_id()
          |> Authority.client(ctx.rpc)
          |> Authority.create(authdata_id, identity)

        {:ok, api_key} =
          ApiKeyRepository.issue(authdata_id, party_id, api_key.name, authdata.token)

        %IssueApiKeyOk{content: encode_api_key(api_key)}

      :forbidden ->
        %Forbidden{}
    end
  end

  @spec list_api_keys(party_id :: String.t(), query :: Keyword.t(), Context.t()) ::
          ListApiKeysOk.t() | Forbidden.t()
  def list_api_keys(party_id, query, ctx) do
    list_opts = if(query[:status], do: [status_filter: query[:status]], else: [])

    case ctx.auth
         |> Auth.Context.put_operation("ListApiKeys", party_id)
         |> Auth.authorize(rpc_context: ctx.rpc) do
      {:allowed, _} ->
        results = ApiKeyRepository.list(party_id, list_opts)
        results = results |> Enum.map(&encode_api_key/1) |> Enum.sort()
        %ListApiKeysOk{content: %{"results" => results}}

      :forbidden ->
        %Forbidden{}
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
      # TODO: Repository and Autority updates are not run atomically,
      # which means descrepancies are possible between the state reported by the API (active),
      # and the ability to authenticate with such key (none), in the event one or the other fails
      # when running this operation.
      # Temporary fix: manually fix the database with an SQL query.
      # Permanent fix: TD-460

      :ok =
        get_authority_id()
        |> Authority.client(ctx.rpc)
        |> Authority.revoke(api_key.id)

      try do
        {:ok, _} = ApiKeyRepository.revoke(api_key)
      rescue
        ex ->
          require Logger

          Logger.error(
            "API key id #{api_key_id} was revoked by authority " <>
              "but I failed to update the database!"
          )

          reraise ex, __STACKTRACE__
      end

      %RevokeApiKeyNoContent{}
    else
      {:error, :not_found} -> %NotFound{}
      :forbidden -> %Forbidden{}
    end
  end

  defp get_authority_id do
    # TODO: Research ways to make it a code option at this level, rather than doing an env fetch
    get_conf(:authority_id) || raise "No authority_id configured for #{__MODULE__}!"
  end

  defp get_deployment_id do
    get_conf(:deployment_id) || @default_deployment_id
  end

  defp get_conf(key) do
    conf = Application.fetch_env!(:api_key_mgmt, __MODULE__)
    conf[key]
  end

  defp encode_api_key(api_key) do
    alias ApiKeyMgmt.ApiKey
    ApiKey.encode(api_key)
  end
end
