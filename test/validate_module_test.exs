defmodule ValidateModuleTest do
  use ExUnit.Case, async: false
  use ExUnitProperties
  import PropertyGenerator

  describe "validate_module/2" do
    test "validates all public functions in a module" do
      validate_module(TestModuleForValidation)
    end

    test "validates all public functions with verbose option" do
      validate_module(TestModuleForValidation, verbose: false)
    end
  end

  describe "validate_module with AB module" do
    test "validates AB module functions" do
      validate_module(AB)
    end
  end
end
