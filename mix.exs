defmodule ApiKeyMgmtUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp aliases do
    [test: ["compile", "cmd mix test"]]
  end

  defp deps do
    []
  end

  defp releases do
    [
      "api-key-mgmt": [
        version: "0.1.0",
        applications: [
          api_key_mgmt: :permanent
        ],
        include_executables_for: [:unix],
        include_erts: false
      ]
    ]
  end
end
