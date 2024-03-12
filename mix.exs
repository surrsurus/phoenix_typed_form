defmodule PhoenixTypedForm.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_typed_form,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      namme: "Phoenix Typed Form",
      source_url: "https://github.com/surrsurus/phoenix_typed_form",
      description: "A macro that enforces a typed schema for your Phoenix LiveView forms"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 0.20.13"},
      {:phoenix, "~> 1.7.11"},
      {:typed_ecto_schema, "~> 0.4.1"}
    ]
  end

  defp package() do
    [
      name: "phoenix_typed_form",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["BSD-2-Clause"],
      links: %{"GitHub" => "https://github.com/surrsurus/phoenix_typed_form"}
    ]
  end
end
