defmodule Plugger.Protocol do
  @moduledoc false
  defprotocol Response do
    @moduledoc """
    A protocol that puts response information into a Plug.Conn.
    """
    @spec put_response(t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(response, conn)
  end
end
