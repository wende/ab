defmodule FunctionTypeFunctions do
  @moduledoc """
  Test functions using function types
  """

  @spec apply_func((integer() -> integer()), integer()) :: integer()
  def apply_func(f, x), do: f.(x)

  @spec map_with((any() -> any()), list()) :: list()
  def map_with(f, list), do: Enum.map(list, f)

  @spec filter_with((any() -> boolean()), list()) :: list()
  def filter_with(pred, list), do: Enum.filter(list, pred)

  @spec callback_example((-> :ok)) :: :ok
  def callback_example(callback), do: callback.()
end
