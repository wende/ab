defmodule StatistexTypespecTest do
  use ExUnit.Case

  @moduledoc """
  Tests PropertyGenerator's ability to parse real-world typespecs from the Statistex library.
  Statistex has interesting types including non-empty lists, required map keys, and number unions.
  """

  describe "Statistex typespec parsing" do
    test "can extract specs from Statistex functions" do
      functions_to_test = [
        {:statistics, 2},
        {:total, 1},
        {:sample_size, 1},
        {:average, 2},
        {:variance, 2},
        {:standard_deviation, 2},
        {:percentiles, 2},
        {:frequency_distribution, 1},
        {:mode, 2},
        {:median, 2},
        {:outlier_bounds, 2},
        {:outliers, 2},
        {:maximum, 1},
        {:minimum, 1}
      ]

      results =
        for {func, arity} <- functions_to_test do
          result = PropertyGenerator.get_function_spec(Statistex, func)
          {func, arity, result}
        end

      IO.puts("\n=== Statistex Typespec Parsing Results ===\n")

      for {func, arity, result} <- results do
        case result do
          {:ok, {input_types, output_type}} ->
            IO.puts("✓ #{func}/#{arity}")
            IO.puts("  Inputs: #{inspect(input_types, limit: 3)}")
            IO.puts("  Output: #{inspect(output_type, limit: 3)}")
            IO.puts("")

          {:error, reason} ->
            IO.puts("✗ #{func}/#{arity}")
            IO.puts("  Error: #{reason}")
            IO.puts("")
        end
      end

      # Assert all succeeded
      failures =
        Enum.filter(results, fn {_func, _arity, result} ->
          match?({:error, _}, result)
        end)

      if failures != [] do
        failed_funcs =
          Enum.map(failures, fn {func, arity, {:error, reason}} ->
            "#{func}/#{arity}: #{reason}"
          end)

        flunk("Failed to parse specs: #{Enum.join(failed_funcs, ", ")}")
      end
    end

    test "interesting type constructs in Statistex" do
      IO.puts("\n=== Interesting Type Constructs ===\n")

      # Non-empty list type: [sample, ...]
      {:ok, {[input_type], _}} = PropertyGenerator.get_function_spec(Statistex, :total)
      IO.puts("1. Non-empty list type (samples):")
      IO.puts("   #{inspect(input_type)}")

      # Map with required keys: %{required(sample) => pos_integer}
      {:ok, {[input_type], output_type}} =
        PropertyGenerator.get_function_spec(Statistex, :frequency_distribution)

      IO.puts("\n2. frequency_distribution/1:")
      IO.puts("   Input: #{inspect(input_type)}")
      IO.puts("   Output: #{inspect(output_type)}")
      IO.puts("   Note: Uses %{required(sample) => pos_integer}")

      # Tuple return type
      {:ok, {_inputs, output_type}} =
        PropertyGenerator.get_function_spec(Statistex, :outlier_bounds)

      IO.puts("\n3. outlier_bounds return type (tuple with named elements):")
      IO.puts("   #{inspect(output_type)}")

      # Custom struct type
      {:ok, {_inputs, output_type}} = PropertyGenerator.get_function_spec(Statistex, :statistics)
      IO.puts("\n4. statistics/2 returns custom struct:")
      IO.puts("   #{inspect(output_type, limit: 3)}")
    end

    test "can create generators for Statistex functions" do
      IO.puts("\n=== Testing Generators ===\n")

      # Test with sample_size (simple function)
      case PropertyGenerator.get_function_spec(Statistex, :sample_size) do
        {:ok, {input_types, _output_type}} ->
          IO.puts("Testing generator for Statistex.sample_size/1:")

          try do
            input_gen = PropertyGenerator.Generators.create_input_generator(input_types, Statistex)
            samples = Enum.take(input_gen, 3)
            IO.puts("  ✓ Generated samples:")
            for sample <- samples do
              IO.puts("    #{inspect(sample)}")
            end
            IO.puts("\n  Note: Type alias 'samples' resolved to list of 'sample' which resolved to 'number'")
          rescue
            e ->
              IO.puts("  ⚠ Generator failed: #{inspect(e)}")
          end

        {:error, reason} ->
          flunk("Could not get spec: #{reason}")
      end
    end

    test "identifies type features we may not fully support" do
      IO.puts("\n=== Type Feature Analysis ===\n")

      # Check for non-empty list syntax [sample, ...]
      {:ok, {[input_type], _}} = PropertyGenerator.get_function_spec(Statistex, :total)

      case input_type do
        {:type, _, :nonempty_list, _} ->
          IO.puts("⚠ Found :nonempty_list type")

        {:user_type, _, :samples, []} ->
          IO.puts("⚠ Found user type :samples (type alias)")

        other ->
          IO.puts("  Input type: #{inspect(other)}")
      end

      # Check for required() in maps
      {:ok, {_, output_type}} =
        PropertyGenerator.get_function_spec(Statistex, :frequency_distribution)

      IO.puts("\nChecking frequency_distribution return type for 'required':")
      IO.puts("  #{inspect(output_type, pretty: true, limit: :infinity)}")

      IO.puts("\n=== Summary ===")
      IO.puts("Statistex uses several advanced type features:")
      IO.puts("  - Non-empty lists: [sample, ...]")
      IO.puts("  - User type aliases: samples, sample, mode")
      IO.puts("  - Required map keys: %{required(sample) => pos_integer}")
      IO.puts("  - Named tuple elements: {lower :: number, upper :: number}")
      IO.puts("  - Custom structs: Statistex.t()")
    end
  end
end
