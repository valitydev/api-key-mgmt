defmodule Plugger.RouterTest do
  @moduledoc """
  Tests for Plugger.Generated.Router
  """

  use ExUnit.Case, async: true
  use Plug.Test
  import Mox

  alias Plugger.Generated.Auth.SecurityScheme.Bearer
  alias Plugger.Generated.MockHandler

  alias Plugger.Generated.Response.{
    GetApiKeyOk,
    IssueApiKeyOk,
    ListApiKeysOk,
    RevokeApiKeyNoContent
  }

  alias Plugger.Generated.Router

  setup do
    MockHandler
    |> stub(:__init__, fn _conn ->
      %{}
    end)
    |> stub(:__authenticate__, fn
      %Bearer{token: "42"}, ctx ->
        {:allow, ctx}
    end)

    :ok
  end

  test "sould get a 404" do
    assert {404, nil} = test_call(:get, "/404")
  end

  describe "request with authorization header" do
    test "should fail without it being defined" do
      conn =
        conn(:get, "/parties/1/api-keys")
        |> assign(:handler, MockHandler)
        |> router_call()

      assert 403 == conn.status
    end
  end

  describe "request with content-type header" do
    test "should fail when its not defined" do
      conn =
        conn(:post, "/parties/1/api-keys")
        |> put_req_header("authorization", "Bearer 42")
        |> assign(:handler, MockHandler)
        |> router_call()

      assert 415 == conn.status
    end

    test "should fail with invalid header provided when body is expected" do
      conn =
        conn(:post, "/parties/1/api-keys")
        |> put_req_header("content-type", "text/html")
        |> put_req_header("authorization", "Bearer 42")
        |> assign(:handler, MockHandler)
        |> router_call()

      assert 415 == conn.status
    end

    test "shoud be ok when no body is expected" do
      MockHandler
      |> expect(:list_api_keys, fn _party_id, [status: :active], _ctx ->
        %ListApiKeysOk{content: []}
      end)

      conn =
        conn(:get, "/parties/1/api-keys?status=Active")
        |> put_req_header("content-type", "text/html")
        |> put_req_header("authorization", "Bearer 42")
        |> assign(:handler, MockHandler)
        |> router_call()

      assert 200 == conn.status
    end
  end

  describe "getApiKey operation" do
    test "should return 200 with correct input" do
      MockHandler
      |> expect(:get_api_key, fn _party_id, api_key_id, _ctx ->
        %GetApiKeyOk{
          content: %{
            createdAt: "2022-10-18T14:21:42+00:00",
            id: api_key_id,
            name: "test_key",
            status: "Active"
          }
        }
      end)

      api_key_id = "test_key"

      assert {200,
              %{
                createdAt: "2022-10-18T14:21:42+00:00",
                id: ^api_key_id,
                name: "test_key",
                status: "Active"
              }} = test_call(:get, "/parties/1/api-keys/#{api_key_id}")
    end

    test "should return 400 with incorrect input" do
      api_key_id = "test_key_that_is_way_longer_than_maximim_allowed"

      assert {400, nil} = test_call(:get, "/parties/1/api-keys/#{api_key_id}")
    end
  end

  describe "issueApiKey operation" do
    test "should return 200 with correct input" do
      key_name = "Test Key"

      key = %{
        name: key_name
      }

      MockHandler
      |> expect(:issue_api_key, fn _party_id, api_key, _ctx ->
        %IssueApiKeyOk{
          content: %{
            createdAt: "2022-10-18T14:21:42+00:00",
            id: "42",
            accessToken: "42",
            name: api_key.name,
            status: "Active"
          }
        }
      end)

      assert {200,
              %{
                createdAt: "2022-10-18T14:21:42+00:00",
                id: "42",
                accessToken: "42",
                name: key_name,
                status: "Active"
              }} ==
               test_call(:post, "/parties/1/api-keys", key |> Jason.encode!())
    end
  end

  describe "listApiKeys operation" do
    test "should return 200 with correct input" do
      test_results = %{
        results: [
          %{
            createdAt: "2022-10-18T14:21:42+00:00",
            id: "42",
            name: "42",
            status: "Active"
          }
        ]
      }

      MockHandler
      |> expect(:list_api_keys, fn _party_id, [status: :active], _ctx ->
        %ListApiKeysOk{content: test_results}
      end)

      assert {200, test_results} == test_call(:get, "/parties/1/api-keys?status=Active")
    end
  end

  describe "revokeApiKey operation" do
    test "should return 204 with correct input" do
      party_id = "party_id"
      api_key_id = "api_key_id"

      MockHandler
      |> expect(:revoke_api_key, fn ^party_id, ^api_key_id, "Revoked", _ctx ->
        %RevokeApiKeyNoContent{}
      end)

      assert {204, nil} =
               test_call(
                 :put,
                 "/parties/#{party_id}/api-keys/#{api_key_id}/status",
                 "\"Revoked\""
               )
    end

    test "should return 400 with incorrect input" do
      assert {400, nil} =
               test_call(
                 :put,
                 "/parties/1/api-keys/1/status",
                 "\"Blah\""
               )
    end
  end

  defp test_call(method, path, params_or_body \\ nil) do
    conn =
      conn(method, path, params_or_body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer 42")
      |> assign(:handler, MockHandler)
      |> router_call()

    resp_body =
      case conn.resp_body do
        "" -> nil
        body -> body |> Jason.decode!(keys: :atoms!)
      end

    {conn.status, resp_body}
  end

  defp router_call(conn) do
    Router.call(conn, Router.init([]))
  end
end
