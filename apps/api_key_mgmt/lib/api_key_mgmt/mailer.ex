defmodule ApiKeyMgmt.Mailer do
  @moduledoc """
  Provides mailer configuration
  """
  use Bamboo.Mailer, otp_app: :api_key_mgmt

  @spec get_email() :: String.t()
  def get_email do
    conf = Application.fetch_env!(:api_key_mgmt, __MODULE__)
    conf[:email]
  end
end
