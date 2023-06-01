defmodule ApiKeyMgmt.Email do
  @moduledoc """
  Email templates
  """
  import Bamboo.Email
  alias ApiKeyMgmt.Mailer

  @spec revoke_email(String.t(), String.t(), String.t(), String.t()) :: Bamboo.Email.t()
  def revoke_email(email, party_id, api_key_id, revoke_token) do
    new_email(
      to: email,
      from: Mailer.get_email(),
      subject: "Revoking Api Key",
      html_body: revoke_html_body(party_id, api_key_id, revoke_token),
      text_body: revoke_html_body(party_id, api_key_id, revoke_token)
    )
  end

  defp get_url do
    conf = Application.fetch_env!(:api_key_mgmt, __MODULE__)
    conf[:url]
  end

  defp revoke_html_body(party_id, api_key_id, revoke_token) do
    "To revoke key, go to link: #{get_url()}/orgs/#{party_id}/revoke-api-key/#{api_key_id}?apiKeyRevokeToken=#{revoke_token}"
  end
end
