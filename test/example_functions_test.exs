defmodule ExampleFunctionsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import PropertyGenerator

  @moduledoc """
  Test suite for PropertyGenerator library functionality.

  Tests PropertyGenerator's ability to:
  - Generate property tests from typespecs (property_test macro)
  - Generate invalid input tests (robust_test macro)
  - Compare function implementations (compare_test macro)
  - Parse and analyze typespecs (API functions)

  Note: ExampleFunctions is used as test data, not the subject under test.
  """

  describe "Basic property_test - validates function outputs match typespecs" do
    # Tests integer operations
    property_test(ExampleFunctions, :add_integers)

    # Tests string operations
    property_test(ExampleFunctions, :concat_strings)

    # Tests list operations
    property_test(ExampleFunctions, :list_length)

    # Tests map operations
    property_test(ExampleFunctions, :get_keys)

    # Tests boolean operations
    property_test(ExampleFunctions, :negate)

    # Tests tuple creation
    property_test(ExampleFunctions, :make_tuple)

    # Tests union types (integer() | String.t())
    property_test(ExampleFunctions, :process_value)

    # Tests range types
    property_test(ExampleFunctions, :validate_percentage)

    # Tests list filtering
    property_test(ExampleFunctions, :filter_positive)

    # Tests atom operations
    property_test(ExampleFunctions, :atom_to_string)
  end

  describe "robust_test - ensures functions handle invalid inputs gracefully" do
    # These tests verify that functions either:
    # 1. Raise errors when given invalid input types, OR
    # 2. Have proper guards/validation that prevent type mismatches
    #
    # Note: Some Elixir functions are polymorphic (e.g., arithmetic accepts floats/integers)
    # so we only test functions with stricter type requirements

    robust_test(ExampleFunctions, :concat_strings)
    robust_test(ExampleFunctions, :list_length)
    robust_test(ExampleFunctions, :negate)
    robust_test(ExampleFunctions, :atom_to_string)
  end

  describe "compare_test - validates two implementations behave identically" do
    # Comparing :add_integers with itself (trivial but demonstrates feature)
    compare_test({ExampleFunctions, :add_integers}, {ExampleFunctions, :add_integers})

    # Comparing :concat_strings with itself
    compare_test({ExampleFunctions, :concat_strings}, {ExampleFunctions, :concat_strings})
  end

  describe "PropertyGenerator API functions" do
    test "get_function_spec returns correct spec" do
      assert {:ok,
              {[{:type, _, :integer, []}, {:type, _, :integer, []}], {:type, _, :integer, []}}} =
               PropertyGenerator.get_function_spec(ExampleFunctions, :add_integers)

      assert {:ok, _} = PropertyGenerator.get_function_spec(ExampleFunctions, :concat_strings)
    end

    test "get_function_spec returns error for non-existent function" do
      assert {:error, _} = PropertyGenerator.get_function_spec(ExampleFunctions, :non_existent)
    end

    test "infer_result_type correctly identifies types" do
      assert PropertyGenerator.infer_result_type(42) == "integer"
      assert PropertyGenerator.infer_result_type("hello") == "binary/string"
      assert PropertyGenerator.infer_result_type([1, 2, 3]) == "list"
      assert PropertyGenerator.infer_result_type(%{a: 1}) == "map"
      assert PropertyGenerator.infer_result_type({:ok, "value"}) == "tuple"
      assert PropertyGenerator.infer_result_type(:atom) == "atom"
    end

    test "types_equivalent? compares types correctly" do
      int_type = {:type, 0, :integer, []}
      assert PropertyGenerator.types_equivalent?(int_type, int_type)

      string_type = {:type, 0, :binary, []}
      refute PropertyGenerator.types_equivalent?(int_type, string_type)
    end
  end
end
