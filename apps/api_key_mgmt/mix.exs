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
    ] |> umbrella()
  end

  defp umbrella(project) do
    project ++ [
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
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
      # Log utils
      {:log_fmt, in_umbrella: true},
      # REST API
      {:plug, "~> 1.13"},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:open_api_spex, git: "https://github.com/kehitt/open_api_spex.git", branch: "fix-cast-and-validate-read-only"},
      # Database
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.16.5"},
      # RPC Clients
      {:bouncer, in_umbrella: true},
      {:token_keeper, in_umbrella: true},
      {:org_management, in_umbrella: true},
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
