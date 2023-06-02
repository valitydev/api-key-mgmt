defmodule Plugger.Generated.Auth do
  @moduledoc false
  defmodule SecurityScheme do
    @moduledoc false
    defmodule Bearer do
      @moduledoc false
      @enforce_keys [:token]
      defstruct [:token]

      @type t :: %__MODULE__{
              token: String.t()
            }
    end

    @type t() :: Bearer.t()

    @spec parse(Plug.Conn.t()) :: {:ok, t()} | {:error, :undefined_security_scheme}
    def parse(conn) do
      authorization = List.keyfind(conn.req_headers, "authorization", 0)

      case authorization do
        # DISCUSS case sensitive match for 'Bearer'
        {"authorization", "Bearer" <> rest} -> {:ok, %Bearer{token: String.trim(rest)}}
        _notfound -> {:error, :undefined_security_scheme}
      end
    end
  end
end
