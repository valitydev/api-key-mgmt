defmodule ApiKeyMgmt.MixProject do
  use Mix.Project

  def project do
    [
      app: :api_key_mgmt,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      dialyzer: dialyzer(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit]
    ]
  end

  defp preferred_cli_env do
    [
      dialyzer: :test,
      coveralls: :test,
      "coveralls.github": :test,
      "coveralls.html": :test
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ApiKeyMgmt, []}
    ]
  end

  defp deps do
    [
      # REST API
      {:plug, "~> 1.13"},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:open_api_spex, "~> 3.14"},
      # Database
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.16.5"},
      # RPC
      {:woody_ex, git: "https://github.com/valitydev/woody_ex.git", branch: "master"},
      # Protocols
      {:bouncer_proto, git: "https://github.com/valitydev/bouncer-proto.git", branch: "master"},
      {:token_keeper_proto,
       git: "https://github.com/valitydev/token-keeper-proto.git", branch: "master"},
      {:org_management_proto,
       git: "https://github.com/valitydev/org-management-proto.git", branch: "master"},
      # Utility
      {:snowflake, git: "https://github.com/valitydev/snowflake.git", branch: "master"},
      # Test deps
      {:finch, "~> 0.13", only: [:dev, :test]},
      {:mox, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.15", only: :test},
      # Dev deps
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
