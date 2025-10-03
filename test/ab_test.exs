defmodule ABTest do
  use ExUnit.Case, async: false
  use ExUnitProperties
  import PropertyGenerator

  describe "AB.a" do
    @describetag :consistency

    property_test(AB, :a)
    robust_test(AB, :a)
  end

  describe "AB.b" do
    @describetag :consistency
    property_test(AB, :b)
    robust_test(AB, :b)
  end

  describe "AB function comparison tests" do
    @describetag :comparison
    compare_test({AB, :a}, {AB, :b})
  end

  describe "AB benchmark comparison" do
    @describetag :performance
    benchmark_test({AB, :a}, {AB, :b}, time: 1, memory_time: 0.5)
  end
end
