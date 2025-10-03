defmodule NumberFunctions do
  @moduledoc """
  Test functions using number() type
  """

  @spec add_numbers(number(), number()) :: number()
  def add_numbers(a, b), do: a + b

  @spec is_positive(number()) :: boolean()
  def is_positive(n), do: n > 0

  @spec abs_value(number()) :: number()
  def abs_value(n) when n < 0, do: -n
  def abs_value(n), do: n
end
