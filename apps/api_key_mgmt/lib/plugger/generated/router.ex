defmodule Plugger.Generated.Router do
  @moduledoc false
  use Plug.Router

  alias Plugger.Generated.Auth.SecurityScheme
  alias Plugger.Generated.Spec
  alias Plugger.Protocol.Response, as: ResponseProtocol

  plug(Plugger.Plug.ContentType,
    allowed_types: ["application/json"]
  )

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  get "/parties/:partyId/api-keys/:apiKeyId" do
    with {:ok, conn} <- Spec.cast_and_validate(conn, :get_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      handler = conn.assigns[:handler]
      handler_ctx = handler.__init__(conn)

      case handler.__authenticate__(security_scheme, handler_ctx) do
        {:allow, handler_ctx} ->
          response = handler.get_api_key(partyId, apiKeyId, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()

        :deny ->
          send_resp(conn, :forbidden, "")
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, _errors}} ->
        send_resp(conn, :bad_request, "")
    end
  end

  post "/parties/:partyId/api-keys" do
    with {:ok, conn} <- Spec.cast_and_validate(conn, :issue_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      handler = conn.assigns[:handler]
      handler_ctx = handler.__init__(conn)

      case handler.__authenticate__(security_scheme, handler_ctx) do
        {:allow, handler_ctx} ->
          api_key = conn.body_params
          response = handler.issue_api_key(partyId, api_key, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()

        :deny ->
          send_resp(conn, :forbidden, "")
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, _errors}} ->
        send_resp(conn, :bad_request, "")
    end
  end

  get "/parties/:partyId/api-keys" do
    with {:ok, conn} <- Spec.cast_and_validate(conn, :list_api_keys),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      conn = Plug.Conn.fetch_query_params(conn)

      handler = conn.assigns[:handler]
      handler_ctx = handler.__init__(conn)

      case handler.__authenticate__(security_scheme, handler_ctx) do
        {:allow, handler_ctx} ->
          query =
            Enum.into(conn.query_params, Keyword.new(), fn {k, v} ->
              {k |> Macro.underscore() |> String.to_existing_atom(),
               v |> Macro.underscore() |> String.to_existing_atom()}
            end)

          response = handler.list_api_keys(partyId, query, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()

        :deny ->
          send_resp(conn, :forbidden, "")
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, _errors}} ->
        send_resp(conn, :bad_request, "")
    end
  end

  put "/parties/:partyId/api-keys/:apiKeyId/status" do
    with {:ok, conn} <- Spec.cast_and_validate(conn, :revoke_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      handler = conn.assigns[:handler]
      handler_ctx = handler.__init__(conn)

      case handler.__authenticate__(security_scheme, handler_ctx) do
        {:allow, handler_ctx} ->
          status = Map.get(conn.body_params, "_json")
          response = handler.revoke_api_key(partyId, apiKeyId, status, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()

        :deny ->
          send_resp(conn, :forbidden, "")
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, _errors}} ->
        send_resp(conn, :bad_request, "")
    end
  end

  match _ do
    send_resp(conn, :not_found, "")
  end
end
