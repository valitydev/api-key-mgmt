defmodule ApiKeyMgmt.Handler do
  @moduledoc """
  Core logic of the service.
  """
  @behaviour Plugger.Generated.Handler
  alias ApiKeyMgmt.{ApiKey, ApiKeyRepository, Auth, Email, Mailer}
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

  require Logger

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
        rpc: RpcContext.new(deadline: make_deadline(ts_now)),
        auth: AuthContext.new(request_origin, conn.remote_ip, deployment_id, ts_now)
      }
    end

    defp make_deadline(datetime_now) do
      naive_dt =
        (datetime_now || DateTime.now!("Etc/UTC"))
        |> DateTime.add(1, :minute)
        |> DateTime.to_naive()

      {microsec, _precision} = naive_dt.microsecond

      {NaiveDateTime.to_erl(naive_dt), Integer.floor_div(microsec, 1000)}
    end
  end

  @spec __init__(conn :: Plug.Conn.t()) :: Context.t()
  def __init__(conn) do
    context = Context.new(conn, get_deployment_id())
    :ok = add_logger_rpc_meta(context.rpc)
    context
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
         {:allowed, _} <- authorize_operation(ctx, "GetApiKey", party_id, api_key_id, api_key) do
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

    case authorize_operation(ctx, "IssueApiKey", party_id) do
      {:allowed, _} ->
        {:ok, authdata} =
          get_authority_id()
          |> Authority.client(ctx.rpc)
          |> Authority.create(authdata_id, identity)

        metadata = Map.get(api_key, :metadata)

        {:ok, api_key} =
          ApiKeyRepository.issue(authdata_id, party_id, api_key.name, authdata.token, metadata)

        %IssueApiKeyOk{content: encode_api_key(api_key)}

      :forbidden ->
        %Forbidden{}
    end
  end

  @spec list_api_keys(party_id :: String.t(), query :: Keyword.t(), Context.t()) ::
          ListApiKeysOk.t() | Forbidden.t()
  def list_api_keys(party_id, query, ctx) do
    list_opts = if(query[:status], do: [status_filter: query[:status]], else: [])

    case authorize_operation(ctx, "ListApiKeys", party_id) do
      {:allowed, _} ->
        results = ApiKeyRepository.list(party_id, list_opts)
        results = results |> Enum.map(&encode_api_key/1) |> Enum.sort()
        %ListApiKeysOk{content: %{"results" => results}}

      :forbidden ->
        %Forbidden{}
    end
  end

  @spec request_revoke_api_key(
          party_id :: String.t(),
          api_key_id :: String.t(),
          body :: String.t(),
          Context.t()
        ) :: RevokeApiKeyNoContent.t() | NotFound.t() | Forbidden.t()
  def request_revoke_api_key(
        party_id,
        api_key_id,
        "Revoked",
        %Context{
          auth: %ApiKeyMgmt.Auth.Context{
            identity: %TokenKeeper.Identity{type: %TokenKeeper.Identity.User{email: email}}
          }
        } = ctx
      ) do
    with {:ok, api_key} <- ApiKeyRepository.get(api_key_id),
         {:allowed, _} <- authorize_operation(ctx, "RevokeApiKey", party_id, api_key_id, api_key),
         {:ok, revoke_token} <- set_revoke_token(api_key_id, api_key) do
      Email.revoke_email(email, party_id, api_key_id, revoke_token)
      |> Mailer.deliver_now!()

      %RevokeApiKeyNoContent{}
    else
      {:error, :not_found} -> %NotFound{}
      :forbidden -> %Forbidden{}
    end
  end

  def request_revoke_api_key(_party_id, _api_key_id, _body, _ctx) do
    %Forbidden{}
  end

  defp set_revoke_token(api_key_id, api_key) do
    revoke_token = UUID.uuid4()

    try do
      {:ok, _} = ApiKeyRepository.set_revoke_token(api_key, revoke_token)
      {:ok, revoke_token}
    rescue
      ex ->
        require Logger

        Logger.error("API key id #{api_key_id} revoke token couldn't be saved")

        reraise ex, __STACKTRACE__
    end
  end

  @spec revoke_api_key(
          party_id :: String.t(),
          api_key_id :: String.t(),
          revoke_token :: String.t(),
          body :: String.t(),
          Context.t()
        ) :: RevokeApiKeyNoContent.t() | NotFound.t() | Forbidden.t()
  def revoke_api_key(party_id, api_key_id, revoke_token, "Revoked", ctx) do
    with {:ok, api_key} <- ApiKeyRepository.get(api_key_id),
         ^revoke_token <- api_key.revoke_token,
         ^party_id <- api_key.party_id do
      # TODO: Repository and Authority updates are not run atomically,
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
      _unmatched_credentials -> %NotFound{}
    end
  end

  ##

  defp add_logger_rpc_meta(rpc_context) do
    rpc_context.rpc_id
    |> Enum.into(Keyword.new())
    |> Logger.metadata()
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

  defp authorize_operation(ctx, operation, party_id) do
    ctx.auth
    |> Auth.Context.put_operation(operation, party_id)
    |> Auth.authorize(rpc_context: ctx.rpc)
  end

  defp authorize_operation(ctx, operation, party_id, api_key_id, api_key) do
    ctx.auth
    |> Auth.Context.put_operation(operation, party_id, api_key_id)
    |> Auth.Context.add_operation_entity(api_key)
    |> Auth.authorize(rpc_context: ctx.rpc)
  end
end
