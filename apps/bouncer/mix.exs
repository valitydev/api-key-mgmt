defmodule Bouncer.MixProject do
  use Mix.Project

  def project do
    [
      app: :bouncer,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # RPC
      {:woody_ex, git: "https://github.com/valitydev/woody_ex.git", branch: "master"},
      # Protocols
      {:bouncer_proto, git: "https://github.com/valitydev/bouncer-proto.git", branch: "master"},
      # Test deps
      {:mox, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.15", only: :test},
      # Dev deps
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
