defmodule TokenKeeper.Authority.Client.WoodyTest do
  @moduledoc """
  Tests for Woody implementation of TokenKeeper.Authority.Client behaviour.
  """
  # Can't run async mode when relying on app env
  use ExUnit.Case, async: false

  alias TokenKeeper.Authority.Client.Woody, as: Client
  alias Woody.Generated.TokenKeeper.Keeper.TokenAuthority, as: Service
  alias Woody.Server.Http, as: Server

  defmodule MockHandler do
    @moduledoc false

    @behaviour Service.Handler

    @spec new(http_path :: String.t(), fun(), options :: Keyword.t()) :: Service.Handler.t()
    def new(http_path, fun, options \\ []) do
      Service.Handler.new({__MODULE__, handler_fun: fun}, http_path, options)
    end

    @spec create(
            id :: String.t(),
            context :: Bouncer.Context.ContextFragment.t(),
            metadata :: %{String.t() => String.t()},
            ctx :: Woody.Context.t(),
            hdlops :: Handler.hdlopts()
          ) ::
            {:ok, TokenKeeper.Keeper.AuthData.t()}
            | {:error, TokenKeeper.Keeper.AuthDataAlreadyExists.t()}
    @impl Service.Handler
    def create(id, context, metadata, _ctx, hdlopts) do
      hdlopts[:handler_fun][:create].(id, context, metadata)
    end

    @spec get(id :: String.t(), ctx :: Woody.Context.t(), hdlops :: Handler.hdlopts()) ::
            {:ok, TokenKeeper.Keeper.AuthData.t()}
            | {:error, TokenKeeper.Keeper.AuthDataNotFound.t()}
    @impl Service.Handler
    def get(id, _ctx, hdlopts) do
      hdlopts[:handler_fun][:get].(id)
    end

    @spec revoke(id :: String.t(), ctx :: Woody.Context.t(), hdlops :: Handler.hdlopts()) ::
            :ok | {:error, TokenKeeper.Keeper.AuthDataNotFound.t()}
    @impl Service.Handler
    def revoke(id, _ctx, hdlopts) do
      hdlopts[:handler_fun][:revoke].(id)
    end
  end

  test "should reply ok" do
    id = "42"

    mock_woody(:test_authority,
      revoke: fn ^id ->
        {:ok, nil}
      end
    )

    assert {:ok, nil} ==
             Client.new(:test_authority, Woody.Context.new()) |> Client.revoke(id)
  end

  test "should reply with an exception" do
    id = "42"

    mock_woody(:test_authority,
      revoke: fn ^id ->
        {:error, %TokenKeeper.Keeper.AuthDataNotFound{}}
      end
    )

    assert {:exception, %TokenKeeper.Keeper.AuthDataNotFound{}} ==
             Client.new(:test_authority, Woody.Context.new()) |> Client.revoke(id)
  end

  defp mock_woody(authority_id, handler_fn) do
    start_supervised!(
      Server.child_spec(
        __MODULE__,
        Server.Endpoint.loopback(),
        MockHandler.new("/authority/#{authority_id}", handler_fn,
          event_handler: Woody.EventHandler.Default
        )
      )
    )

    endpoint = Server.endpoint(__MODULE__)

    Application.put_env(:token_keeper, TokenKeeper.Authority.Client.Woody, [
      {authority_id, url: "http://#{endpoint}/authority/#{authority_id}"}
    ])

    :ok
  end
end
