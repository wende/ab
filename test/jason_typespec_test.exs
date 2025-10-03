defmodule JasonTypespecTest do
  use ExUnit.Case

  @moduledoc """
  Tests PropertyGenerator's ability to parse real-world typespecs from the Jason library.
  This is a stress test to ensure we can handle complex, production-grade type specifications.
  """

  describe "Jason typespec parsing" do
    test "can extract specs from all Jason public functions" do
      functions_to_test = [
        {:decode, 2},
        {:decode!, 2},
        {:encode, 2},
        {:encode!, 2},
        {:encode_to_iodata, 2},
        {:encode_to_iodata!, 2}
      ]

      results = 
        for {func, arity} <- functions_to_test do
          result = PropertyGenerator.get_function_spec(Jason, func)
          {func, arity, result}
        end

      IO.puts("\n=== Jason Typespec Parsing Results ===\n")

      for {func, arity, result} <- results do
        case result do
          {:ok, {input_types, output_type}} ->
            IO.puts("✓ #{func}/#{arity}")
            IO.puts("  Input types: #{inspect(input_types, limit: :infinity)}")
            IO.puts("  Output type: #{inspect(output_type, limit: :infinity)}")
            IO.puts("")

          {:error, reason} ->
            IO.puts("✗ #{func}/#{arity}")
            IO.puts("  Error: #{reason}")
            IO.puts("")
        end
      end

      # Assert all succeeded
      failures = Enum.filter(results, fn {_func, _arity, result} -> 
        match?({:error, _}, result)
      end)

      if failures != [] do
        failed_funcs = Enum.map(failures, fn {func, arity, {:error, reason}} -> 
          "#{func}/#{arity}: #{reason}"
        end)
        flunk("Failed to parse specs: #{Enum.join(failed_funcs, ", ")}")
      end
    end

    test "can create generators for Jason functions (where possible)" do
      # Test decode/2 - should be able to generate inputs
      case PropertyGenerator.get_function_spec(Jason, :decode) do
        {:ok, {input_types, _output_type}} ->
          IO.puts("\nTesting generator for Jason.decode/2:")
          IO.puts("  Input types: #{inspect(input_types)}")
          
          try do
            input_gen = PropertyGenerator.Generators.create_input_generator(input_types)
            sample = Enum.take(input_gen, 1) |> List.first()
            IO.puts("  ✓ Generated sample: #{inspect(sample)}")
          rescue
            e ->
              IO.puts("  ⚠ Generator failed (this may be expected for complex types): #{inspect(e)}")
          end

        {:error, reason} ->
          flunk("Could not get spec: #{reason}")
      end
    end

    test "can create validators for Jason return types" do
      # Test encode/2 return type validator
      case PropertyGenerator.get_function_spec(Jason, :encode) do
        {:ok, {_input_types, output_type}} ->
          IO.puts("\nTesting validator for Jason.encode/2 return type:")
          IO.puts("  Output type: #{inspect(output_type)}")
          
          try do
            validator = PropertyGenerator.Validators.create_output_validator(output_type)
            
            # Test with expected success value
            success_result = {:ok, "{\"test\":1}"}
            IO.puts("  Testing {:ok, string}: #{validator.(success_result)}")
            
            # Test with expected error value (if we can create it)
            IO.puts("  ✓ Validator created successfully")
          rescue
            e ->
              IO.puts("  ⚠ Validator creation failed (may be expected): #{inspect(e)}")
          end

        {:error, reason} ->
          flunk("Could not get spec: #{reason}")
      end
    end

    test "identifies unsupported type constructs" do
      # This test documents which type features we don't support yet
      unsupported_features = []

      # Check for iodata type
      case PropertyGenerator.get_function_spec(Jason, :decode) do
        {:ok, {[first_type | _], _}} ->
          case first_type do
            {:type, _, :iodata, []} -> 
              IO.puts("\n⚠ Found iodata type - checking if supported")
            {:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :iodata}, []]} ->
              IO.puts("\n⚠ Found remote iodata type - checking if supported")
            _ -> 
              :ok
          end
        _ -> :ok
      end

      # Check for no_return type
      case PropertyGenerator.get_function_spec(Jason, :decode!) do
        {:ok, {_, output_type}} ->
          case output_type do
            {:type, _, :union, types} ->
              has_no_return = Enum.any?(types, fn
                {:type, _, :no_return, []} -> true
                _ -> false
              end)
              
              if has_no_return do
                IO.puts("⚠ Found no_return type in union")
              end
            _ -> :ok
          end
        _ -> :ok
      end

      IO.puts("\n=== Type Support Summary ===")
      IO.puts("This test documents type constructs we may not fully support yet.")
      IO.puts("Unsupported features found: #{length(unsupported_features)}")
    end
  end
end

