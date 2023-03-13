defmodule Plugger.Generated.Handler do
  @moduledoc false
  alias Plugger.Generated.Auth.SecurityScheme

  alias Plugger.Generated.Response.{
    Forbidden,
    GetApiKeyOk,
    IssueApiKeyOk,
    ListApiKeysOk,
    NotFound,
    RevokeApiKeyNoContent
  }

  @type ctx :: any

  @callback __init__(conn :: Plug.Conn.t()) :: ctx()
  @callback __authenticate__(SecurityScheme.t(), ctx()) ::
              {:allow, ctx()} | :deny

  @callback get_api_key(party_id :: String.t(), api_key_id :: String.t(), ctx()) ::
              GetApiKeyOk.t() | NotFound.t() | Forbidden.t()
  @callback issue_api_key(party_id :: String.t(), api_key :: map(), ctx()) ::
              IssueApiKeyOk.t() | NotFound.t() | Forbidden.t()
  @callback list_api_keys(party_id :: String.t(), query :: Keyword.t(), ctx()) ::
              ListApiKeysOk.t() | Forbidden.t()
  @callback request_revoke_api_key(
              party_id :: String.t(),
              api_key_id :: String.t(),
              body :: String.t(),
              ctx()
            ) :: RevokeApiKeyNoContent.t() | NotFound.t() | Forbidden.t()
  @callback revoke_api_key(
              party_id :: String.t(),
              api_key_id :: String.t(),
              revoke_token :: String.t(),
              body :: String.t(),
              ctx()
            ) :: RevokeApiKeyNoContent.t() | NotFound.t() | Forbidden.t()
end
