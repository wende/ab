defmodule NumberFunctionsTest do
  use ExUnit.Case
  use ExUnitProperties
  import PropertyGenerator

  describe "number() type support" do
    property_test(NumberFunctions, :add_numbers)
    property_test(NumberFunctions, :is_positive)
    property_test(NumberFunctions, :abs_value)
  end

  test "number() validator accepts integers and floats" do
    validator = PropertyGenerator.Validators.type_to_validator({:type, 0, :number, []})

    assert validator.(42)
    assert validator.(3.14)
    assert validator.(0)
    assert validator.(-1)
    assert validator.(-3.5)

    refute validator.("string")
    refute validator.(:atom)
    refute validator.([1, 2])
  end

  test "number() generator produces mix of integers and floats" do
    generator = PropertyGenerator.Generators.type_to_generator({:type, 0, :number, []})
    samples = Enum.take(generator, 100)

    integers = Enum.count(samples, &is_integer/1)
    floats = Enum.count(samples, &is_float/1)

    # Should have both types
    assert integers > 0, "Should generate some integers"
    assert floats > 0, "Should generate some floats"
    assert integers + floats == 100, "All samples should be numbers"
  end
end
