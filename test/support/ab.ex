defmodule AB do
  @moduledoc """
  Module with two functions for comparison testing.
  """

  @spec a(integer()) :: integer()
  def a(value) when is_integer(value), do: value

  @spec b(integer()) :: integer()
  def b(value) when is_integer(value), do: value
end
