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
    [
      # Rel deps
      {:logstash_logger_formatter,
       git: "https://github.com/valitydev/logstash_logger_formatter.git",
       branch: "master",
       only: [:prod],
       runtime: false}
    ]
  end

  defp releases do
    [
      api_key_mgmt: [
        version: "0.1.0",
        applications: [
          api_key_mgmt: :permanent,
          logstash_logger_formatter: :load
        ],
        include_executables_for: [:unix],
        include_erts: false
      ]
    ]
  end
end
