defmodule PhoenixTypedForm.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_typed_form,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:phoenix, "~> 1.7.11"},
      {:typed_ecto_schema, "~> 0.4.1"}
    ]
  end
end
