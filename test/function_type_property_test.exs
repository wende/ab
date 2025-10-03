defmodule FunctionTypePropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  import PropertyGenerator

  @moduledoc """
  Property tests for functions that accept function arguments
  """

  describe "function type property tests" do
    property_test(FunctionTypeFunctions, :apply_func)
    property_test(FunctionTypeFunctions, :map_with)
    property_test(FunctionTypeFunctions, :filter_with)
    property_test(FunctionTypeFunctions, :callback_example)
  end

  describe "function type robust tests" do
    robust_test(FunctionTypeFunctions, :apply_func)
    robust_test(FunctionTypeFunctions, :map_with)
    robust_test(FunctionTypeFunctions, :filter_with)
    robust_test(FunctionTypeFunctions, :callback_example)
  end

  test "generated functions work correctly" do
    # Get a generator for apply_func which takes (integer -> integer) and integer
    {:ok, {input_types, _}} =
      PropertyGenerator.get_function_spec(FunctionTypeFunctions, :apply_func)

    gen = PropertyGenerator.Generators.create_input_generator(input_types)

    # Generate some inputs
    samples = Enum.take(gen, 5)

    IO.puts("\nTesting generated functions:")

    for [func, x] <- samples do
      result = FunctionTypeFunctions.apply_func(func, x)
      IO.puts("  apply_func(fn, #{x}) = #{result}")
      assert is_integer(result), "Result should be an integer"
      assert is_function(func, 1), "First argument should be a function/1"
    end
  end

  test "function validators work" do
    func_type =
      {:type, 0, :fun,
       [
         {:type, 0, :product, [{:type, 0, :integer, []}]},
         {:type, 0, :integer, []}
       ]}

    validator = PropertyGenerator.Validators.type_to_validator(func_type)

    # Should accept functions
    assert validator.(fn x -> x + 1 end)
    assert validator.(fn _ -> 42 end)

    # Should reject non-functions
    refute validator.(42)
    refute validator.("string")
    refute validator.([1, 2, 3])
  end
end
