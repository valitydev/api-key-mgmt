defmodule Plugger.Plug do
  @moduledoc """
  Custom plugs.
  """
  defmodule ContentType do
    @moduledoc """
    A plug that forces the content-type to be present for HTTP methods that can use it.
    """
    @behaviour Plug
    import Plug.Conn
    alias Plug.{Conn, Conn.Unfetched}

    @methods ~w(POST PUT PATCH DELETE)

    @typep options :: %{allowed_types: [String.t()]}

    @spec init(Keyword.t()) :: options
    @impl Plug
    def init(opts) do
      {allowed_types, _opts} = Keyword.pop(opts, :allowed_types)
      %{allowed_types: allowed_types}
    end

    @spec call(Conn.t(), options) :: Conn.t()
    @impl Plug
    def call(%{method: method, body_params: %Unfetched{}} = conn, options)
        when method in @methods do
      %{allowed_types: allowed_types} = options
      %{req_headers: req_headers} = conn

      case List.keyfind(req_headers, "content-type", 0) do
        {"content-type", ct} ->
          if ct in allowed_types do
            conn
          else
            refute(conn)
          end

        _notfound ->
          refute(conn)
      end
    end

    def call(%{body_params: %Unfetched{}} = conn, _options) do
      conn
    end

    defp refute(conn) do
      conn
      |> send_resp(:unsupported_media_type, "")
      |> halt()
    end
  end
end
