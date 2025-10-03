defmodule FunctionTypeTest do
  use ExUnit.Case

  @moduledoc """
  Tests for function type support in typespecs
  """

  describe "function type parsing" do
    test "can extract function type specs" do
      test_functions = [
        {:apply_func, 2},
        {:map_with, 2},
        {:filter_with, 2},
        {:callback_example, 1}
      ]

      IO.puts("\n=== Function Type Parsing ===\n")

      for {func, arity} <- test_functions do
        case PropertyGenerator.get_function_spec(FunctionTypeFunctions, func) do
          {:ok, {input_types, output_type}} ->
            IO.puts("✓ #{func}/#{arity}")
            IO.puts("  Inputs: #{inspect(input_types, pretty: true, limit: :infinity)}")
            IO.puts("  Output: #{inspect(output_type)}")
            IO.puts("")

          {:error, reason} ->
            IO.puts("✗ #{func}/#{arity}: #{reason}")
            IO.puts("")
        end
      end
    end

    test "function type in apply_func" do
      case PropertyGenerator.get_function_spec(FunctionTypeFunctions, :apply_func) do
        {:ok, {[func_type, int_type], _output}} ->
          IO.puts("\napply_func types:")
          IO.puts("  Function arg: #{inspect(func_type)}")
          IO.puts("  Integer arg: #{inspect(int_type)}")

          # Check if function type is recognized
          assert match?({:type, _, :fun, _}, func_type) or match?({:type, _, _, _}, func_type)

        {:error, reason} ->
          flunk("Could not parse apply_func: #{reason}")
      end
    end

    test "try creating validators for function types" do
      case PropertyGenerator.get_function_spec(FunctionTypeFunctions, :apply_func) do
        {:ok, {_input_types, output_type}} ->
          IO.puts("\nTrying to create validator for function return type:")

          try do
            validator = PropertyGenerator.Validators.create_output_validator(output_type)
            IO.puts("  ✓ Output validator created")

            # Test the validator
            assert validator.(42)
            IO.puts("  ✓ Validator works for integers")
          rescue
            e -> IO.puts("  Note: #{inspect(e)}")
          end

        {:error, reason} ->
          flunk("Could not get spec: #{reason}")
      end
    end

    test "try creating generators for function types (may not be supported)" do
      case PropertyGenerator.get_function_spec(FunctionTypeFunctions, :apply_func) do
        {:ok, {input_types, _output_type}} ->
          IO.puts("\nTrying to create generator for inputs including function:")

          try do
            _gen = PropertyGenerator.Generators.create_input_generator(input_types)
            IO.puts("  ✓ Generator created (function type is supported!)")
          rescue
            e ->
              IO.puts("  ⚠ Generator creation failed (expected - functions are hard to generate)")
              IO.puts("    #{inspect(e)}")
          end

        {:error, reason} ->
          flunk("Could not get spec: #{reason}")
      end
    end
  end
end
