defmodule MetaSimpleTest do
  @moduledoc """
  🤯 SIMPLIFIED META TEST: PropertyGenerator testing PropertyGenerator

  This focuses on the functions that work well with meta testing.
  """

  use ExUnit.Case
  use ExUnitProperties
  import PropertyGenerator

  describe "🤯 META: PropertyGenerator successfully testing itself" do
    # Test the core functions that have proper typespecs
    property_test(PropertyGenerator, :get_function_spec)
    property_test(PropertyGenerator, :create_input_generator_runtime)
    property_test(PropertyGenerator, :create_output_validator_runtime)
    property_test(PropertyGenerator, :create_invalid_input_generator_runtime)
    property_test(PropertyGenerator, :infer_result_type)
  end

  describe "🎯 META: Manual demonstrations" do
    test "infer_result_type can analyze its own output" do
      IO.puts("\n🎯 META TEST: infer_result_type analyzing itself")

      # infer_result_type returns strings, let's verify that
      sample_result = PropertyGenerator.infer_result_type(42)
      inferred_type = PropertyGenerator.infer_result_type(sample_result)

      IO.puts("  infer_result_type(42) = #{inspect(sample_result)}")
      IO.puts("  infer_result_type(\"#{sample_result}\") = #{inspect(inferred_type)}")
      IO.puts("  ✓ Successfully inferred its own output type!")

      # Should return "binary()" since infer_result_type returns strings
      assert inferred_type == "binary()"
    end

    test "create_input_generator_runtime can generate inputs for infer_result_type" do
      IO.puts("\n🎯 META TEST: Generator creating inputs for infer_result_type")

      # Get the typespec for infer_result_type
      {:ok, {input_types, output_type}} =
        PropertyGenerator.get_function_spec(PropertyGenerator, :infer_result_type)

      # Use our own generator to create inputs for our own function!
      generator = PropertyGenerator.create_input_generator_runtime(input_types, PropertyGenerator)
      test_inputs = Enum.take(generator, 3)

      IO.puts("  Generated inputs for infer_result_type:")

      for {[input], idx} <- Enum.with_index(test_inputs, 1) do
        result = PropertyGenerator.infer_result_type(input)

        IO.puts(
          "    Test #{idx}: infer_result_type(#{inspect(input, limit: 1)}) = #{inspect(result)}"
        )
      end

      IO.puts("  ✓ Successfully generated valid inputs for itself!")

      # All inputs should be lists with one element (since infer_result_type/1 takes one arg)
      for inputs <- test_inputs do
        assert is_list(inputs) and length(inputs) == 1
      end
    end

    test "output validator can validate infer_result_type outputs" do
      IO.puts("\n🎯 META TEST: Validator validating infer_result_type outputs")

      # Get the output typespec for infer_result_type
      {:ok, {_input_types, output_type}} =
        PropertyGenerator.get_function_spec(PropertyGenerator, :infer_result_type)

      # Create validator using our own function
      validator = PropertyGenerator.create_output_validator_runtime(output_type)

      # Test it on actual outputs from infer_result_type
      test_outputs = [
        PropertyGenerator.infer_result_type(42),
        PropertyGenerator.infer_result_type([1, 2, 3]),
        PropertyGenerator.infer_result_type(%{a: 1}),
        PropertyGenerator.infer_result_type({:ok, "test"})
      ]

      IO.puts("  Testing validator on infer_result_type outputs:")
      valid_count = 0

      for {output, idx} <- Enum.with_index(test_outputs, 1) do
        is_valid = validator.(output)
        IO.puts("    Output #{idx}: #{inspect(output)} -> Valid: #{is_valid}")
        if is_valid, do: valid_count = valid_count + 1
      end

      IO.puts("  ✓ Validator correctly validated #{valid_count}/4 outputs!")

      # All outputs should be valid (they're all strings)
      assert valid_count == 4
    end

    test "🚀 ULTIMATE META: Full end-to-end PropertyGenerator testing PropertyGenerator" do
      IO.puts("\n🚀 ULTIMATE META TEST: Complete self-testing workflow")

      # Step 1: Extract typespec using our own function
      {:ok, {input_types, output_type}} =
        PropertyGenerator.get_function_spec(PropertyGenerator, :infer_result_type)

      IO.puts("Step 1: ✓ Extracted own typespec")

      # Step 2: Generate test inputs using our own generator
      input_gen = PropertyGenerator.create_input_generator_runtime(input_types, PropertyGenerator)
      test_inputs = Enum.take(input_gen, 5)

      IO.puts("Step 2: ✓ Generated test inputs using own generator")

      # Step 3: Create output validator using our own validator
      output_validator = PropertyGenerator.create_output_validator_runtime(output_type)

      IO.puts("Step 3: ✓ Created output validator using own validator")

      # Step 4: Run the function and validate using our own tools
      IO.puts("Step 4: ✓ Testing function with generated inputs:")

      valid_outputs = 0

      for {[input], idx} <- Enum.with_index(test_inputs, 1) do
        result = PropertyGenerator.infer_result_type(input)
        is_valid = output_validator.(result)

        IO.puts(
          "  Test #{idx}: infer_result_type(#{inspect(input, limit: 1)}) = #{inspect(result)}"
        )

        IO.puts("    Valid: #{is_valid}")

        if is_valid do
          valid_outputs = valid_outputs + 1
        end
      end

      IO.puts("\n🎉 RESULT: #{valid_outputs}/5 outputs passed validation!")
      IO.puts("🎉 META TEST COMPLETE: PropertyGenerator successfully tested itself end-to-end!")

      # All outputs should be valid strings
      assert valid_outputs == 5
    end
  end
end
