defmodule Dogfishing.MixProject do
  use Mix.Project

  def project do
    [
      app: :dogfishing,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dogfishing.Application, []}
      # env: [token: "MTM5NjAyMDQ2MDcwOTIxNjM2Nw.GrO0xg.65VCn9V7Ma7_P574aez3kchiYI6P4l9BOF79ZY"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, github: "Kraigie/nostrum"},
      {:req, "~> 0.5.0"}
    ]
  end
end
