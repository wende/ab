defmodule TestModuleForValidation do
  @moduledoc """
  A test module used for validate_module testing.
  """

  @spec add(integer(), integer()) :: integer()
  def add(a, b), do: a + b

  @spec multiply(integer(), integer()) :: integer()
  def multiply(a, b), do: a * b

  @spec divide(integer(), pos_integer() | neg_integer()) :: integer()
  def divide(a, b) when b != 0, do: a / b

  @spec to_string_list([integer()]) :: [String.t()]
  def to_string_list(nums), do: Enum.map(nums, &Integer.to_string/1)
end
