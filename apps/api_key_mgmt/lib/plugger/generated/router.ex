defmodule Plugger.Generated.Router do
  @moduledoc false
  use Plug.Router

  alias Plugger.Generated.Auth.SecurityScheme
  alias Plugger.Generated.Spec
  alias Plugger.Protocol.Response, as: ResponseProtocol

  require Logger

  plug(Plugger.Plug.ContentType,
    allowed_types: ["application/json"]
  )

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  get "/orgs/:partyId/api-keys/:apiKeyId" do
    handler = conn.assigns[:handler]
    handler_ctx = handler.__init__(conn)

    with {:ok, conn} <- Spec.cast_and_validate(conn, :get_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
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

      {:error, {:invalid_request, errors}} ->
        Logger.info("Request validation failed. Reason: #{inspect(errors)}")
        send_resp(conn, :bad_request, make_request_validation_error(errors))
    end
  end

  post "/orgs/:partyId/api-keys" do
    handler = conn.assigns[:handler]
    handler_ctx = handler.__init__(conn)

    with {:ok, conn} <- Spec.cast_and_validate(conn, :issue_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
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

      {:error, {:invalid_request, errors}} ->
        Logger.info("Request validation failed. Reason: #{inspect(errors)}")
        send_resp(conn, :bad_request, make_request_validation_error(errors))
    end
  end

  get "/orgs/:partyId/api-keys" do
    handler = conn.assigns[:handler]
    handler_ctx = handler.__init__(conn)

    with {:ok, conn} <- Spec.cast_and_validate(conn, :list_api_keys),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      conn = Plug.Conn.fetch_query_params(conn)

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

      {:error, {:invalid_request, errors}} ->
        Logger.info("Request validation failed. Reason: #{inspect(errors)}")
        send_resp(conn, :bad_request, make_request_validation_error(errors))
    end
  end

  put "/orgs/:partyId/api-keys/:apiKeyId/status" do
    handler = conn.assigns[:handler]
    handler_ctx = handler.__init__(conn)

    with {:ok, conn} <- Spec.cast_and_validate(conn, :request_revoke_api_key),
         {:ok, security_scheme} <- SecurityScheme.parse(conn) do
      case handler.__authenticate__(security_scheme, handler_ctx) do
        {:allow, handler_ctx} ->
          status = Map.get(conn.body_params, "_json")
          response = handler.request_revoke_api_key(partyId, apiKeyId, status, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()

        :deny ->
          send_resp(conn, :forbidden, "")
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, errors}} ->
        Logger.info("Request validation failed. Reason: #{inspect(errors)}")
        send_resp(conn, :bad_request, make_request_validation_error(errors))
    end
  end

  get "/orgs/:partyId/revoke-api-key/:apiKeyId" do
    handler = conn.assigns[:handler]
    handler_ctx = handler.__init__(conn)

    with {:ok, conn} <- Spec.cast_and_validate(conn, :revoke_api_key),
         conn <- Plug.Conn.fetch_query_params(conn) do
      case conn.query_params do
        # Skip authorization, as origin of token is email, that doesn't have authorization context
        # For proper implementation change bouncer-policies to account for this scenario
        %{"apiKeyRevokeToken" => revoke_token} ->
          status = Map.get(conn.body_params, "_json")
          response = handler.revoke_api_key(partyId, apiKeyId, revoke_token, status, handler_ctx)

          response
          |> ResponseProtocol.put_response(conn)
          |> send_resp()
      end
    else
      {:error, :undefined_security_scheme} ->
        send_resp(conn, :forbidden, "")

      {:error, {:invalid_request, errors}} ->
        Logger.info("Request validation failed. Reason: #{inspect(errors)}")
        send_resp(conn, :bad_request, make_request_validation_error(errors))
    end
  end

  match _ do
    send_resp(conn, :not_found, "")
  end

  defp make_request_validation_error(errors) do
    alias OpenApiSpex.Cast.Error
    reasons = errors |> Enum.map(&Error.message_with_path/1)

    response = %{
      "code" => "invalidRequest",
      "message" => "Request validation failed. Reason: #{reasons}"
    }

    Jason.encode!(response)
  end
end
