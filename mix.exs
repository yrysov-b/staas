defmodule Staas.MixProject do
  use Mix.Project

  def project do
    [
      app: :staas,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Staas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 0.6"},
      {:jason, "~> 1.4"},
      {:redix, "~> 1.1"},
      {:uuid, "~> 1.1"},
      {:httpoison, "~> 2.1"},
      {:castore, ">= 0.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
