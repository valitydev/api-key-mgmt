defmodule ApiKeyMgmtUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [test: ["compile", "cmd mix test"]]
  end

  defp deps do
    []
  end
end
