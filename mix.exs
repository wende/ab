defmodule AB.MixProject do
  use Mix.Project

  def project do
    [
      app: :ab,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),

      # Package metadata
      name: "AB",
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/yourusername/ab"
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Property-based testing - automatic test data generation
      {:stream_data, "~> 1.0"},

      # Benchmarking - performance comparison between implementations
      {:benchee, "~> 1.3"},
      {:benchee_html, "~> 1.0"},

      # Utilities
      {:jason, "~> 1.4"},
      {:decimal, "~> 2.0"},

      # Development and documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --trace"
    ]
  end

  defp description do
    """
    Automatically compare two implementations of the same problem with
    property-based testing and performance benchmarks. Perfect for refactoring,
    algorithm comparison, and validating that different implementations produce
    identical results.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/yourusername/ab",
        "Docs" => "https://hexdocs.pm/ab"
      },
      maintainers: ["Your Name"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/yourusername/ab",
      homepage_url: "https://github.com/yourusername/ab",
      formatters: ["html"]
    ]
  end
end
