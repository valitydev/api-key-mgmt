defmodule LogFmt.MixProject do
  use Mix.Project

  def project do
    [
      app: :log_fmt,
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
      {:jason, "~> 1.0"},
      # Test deps
      {:excoveralls, "~> 0.15", only: :test}
    ]
  end
end
