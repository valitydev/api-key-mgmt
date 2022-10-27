defmodule Plugger.Generated.Response do
  @moduledoc false
  alias Plugger.Protocol.Response, as: ResponseProtocol

  defmodule GetApiKeyOk do
    @moduledoc false
    @enforce_keys [:content]
    defstruct [:content]

    @type t :: %__MODULE__{
            content: map()
          }
  end

  defimpl ResponseProtocol, for: GetApiKeyOk do
    @spec put_response(GetApiKeyOk.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%GetApiKeyOk{content: content}, conn) do
      import Plug.Conn

      conn
      |> put_resp_content_type("application/json")
      |> resp(200, Jason.encode!(content))
    end
  end

  defmodule IssueApiKeyOk do
    @moduledoc false
    @enforce_keys [:content]
    defstruct [:content]

    @type t :: %__MODULE__{
            content: map()
          }
  end

  defimpl ResponseProtocol, for: IssueApiKeyOk do
    @spec put_response(IssueApiKeyOk.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%IssueApiKeyOk{content: content}, conn) do
      import Plug.Conn

      conn
      |> put_resp_content_type("application/json")
      |> resp(200, Jason.encode!(content))
    end
  end

  defmodule ListApiKeysOk do
    @moduledoc false
    @enforce_keys [:content]
    defstruct [:content]

    @type t :: %__MODULE__{
            content: map()
          }
  end

  defimpl ResponseProtocol, for: ListApiKeysOk do
    @spec put_response(ListApiKeysOk.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%ListApiKeysOk{content: content}, conn) do
      import Plug.Conn

      conn
      |> put_resp_content_type("application/json")
      |> resp(200, Jason.encode!(content))
    end
  end

  defmodule RevokeApiKeyNoContent do
    @moduledoc false
    @enforce_keys []
    defstruct []

    @type t :: %__MODULE__{}
  end

  defimpl ResponseProtocol, for: RevokeApiKeyNoContent do
    @spec put_response(RevokeApiKeyNoContent.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%RevokeApiKeyNoContent{}, conn) do
      import Plug.Conn
      resp(conn, 204, "")
    end
  end

  defmodule NotFound do
    @moduledoc false
    defstruct []
    @type t :: %__MODULE__{}
  end

  defimpl ResponseProtocol, for: NotFound do
    @spec put_response(NotFound.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%NotFound{}, conn) do
      import Plug.Conn
      resp(conn, 404, "")
    end
  end

  defmodule Forbidden do
    @moduledoc false
    defstruct []
    @type t :: %__MODULE__{}
  end

  defimpl ResponseProtocol, for: Forbidden do
    @spec put_response(Forbidden.t(), Plug.Conn.t()) :: Plug.Conn.t()
    def put_response(%Forbidden{}, conn) do
      import Plug.Conn
      resp(conn, 403, "")
    end
  end
end
