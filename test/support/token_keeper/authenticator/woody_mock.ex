defmodule TestSupport.TokenKeeper.Autheticator.WoodyMock do
  @moduledoc """
  Helper functions to mock a woody token keeper service in tests
  """
  alias Woody.Generated.TokenKeeper.Keeper.TokenAuthenticator, as: Service
  alias Woody.Server.Http, as: Server

  defmodule MockHandler do
    @moduledoc false
    alias Woody.Server.Http

    @behaviour Service.Handler

    def new(http_path, fun, options) do
      Service.Handler.new({__MODULE__, handler_fun: fun}, http_path, options)
    end

    @spec add_existing_token(
            id :: String.t(),
            context :: Bouncer.Context.ContextFragment.t(),
            metadata :: %{String.t() => String.t()},
            authority :: String.t(),
            ctx :: Woody.Context.t(),
            hdlops :: Http.Handler.hdlopts()
          ) ::
            {:ok, TokenKeeper.Keeper.AuthData.t()}
            | {:error, TokenKeeper.Keeper.AuthDataAlreadyExists.t()}
    @impl true
    def add_existing_token(id, context, metadata, authority, _ctx, hdlopts) do
      hdlopts[:handler_fun][:add_existing_token].(id, context, metadata, authority)
    end

    @spec authenticate(
            token :: String.t(),
            source_context :: TokenKeeper.Keeper.TokenSourceContext.t(),
            ctx :: Woody.Context.t(),
            hdlops :: Http.Handler.hdlopts()
          ) ::
            {:ok, TokenKeeper.Keeper.AuthData.t()}
            | {:error, TokenKeeper.Keeper.InvalidToken.t()}
            | {:error, TokenKeeper.Keeper.AuthDataNotFound.t()}
            | {:error, TokenKeeper.Keeper.AuthDataRevoked.t()}
    @impl true
    def authenticate(token, source_context, _ctx, hdlopts) do
      hdlopts[:handler_fun][:authenticate].(token, source_context)
    end
  end

  @spec mock(any) :: :ok
  def mock(handler_fn) do
    import ExUnit.Callbacks

    start_supervised!(
      Server.child_spec(
        __MODULE__,
        Server.Endpoint.loopback(),
        MockHandler.new("/authenticator", handler_fn, event_handler: Woody.EventHandler.Default)
      )
    )

    endpoint = Server.endpoint(__MODULE__)

    Application.put_env(:api_key_mgmt, TokenKeeper.Authenticator.Client.Woody,
      url: "http://#{endpoint}/authenticator"
    )

    :ok
  end
end
