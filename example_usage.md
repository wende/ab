# Universal Test File Usage Examples

The `test/ab_test.exs` file is completely universal and can test any two functions by simply changing the configuration at the top.

## Current Configuration

```elixir
# Configuration: Define which functions to test
@module_under_test AB
@function_a :a
@function_b :b

# Helper function to get test data generator
defp test_data_generator, do: Generators.integer_lists(max_length: 50)
```

## Example: Testing String Functions

Create a new module:

```elixir
# lib/string_ops.ex
defmodule StringOps do
  def a(str) when is_binary(str) do
    String.reverse(str)
  end

  def b(str) when is_binary(str) do
    str |> String.graphemes() |> Enum.reverse() |> Enum.join()
  end
end
```

Change the test configuration:

```elixir
@module_under_test StringOps
@function_a :a
@function_b :b

defp test_data_generator, do: Generators.strings(max_length: 20)
```

## Example: Testing Math Functions

Create a math module:

```elixir
# lib/math_ops.ex
defmodule MathOps do
  def a(numbers) when is_list(numbers) do
    Enum.sum(numbers)
  end

  def b(numbers) when is_list(numbers) do
    Enum.reduce(numbers, 0, &+/2)
  end
end
```

Change the test configuration:

```elixir
@module_under_test MathOps
@function_a :a
@function_b :b

defp test_data_generator, do: Generators.integer_lists(max_length: 10)
```

## Example: Testing Map Functions

Create a map processing module:

```elixir
# lib/map_ops.ex
defmodule MapOps do
  def a(map) when is_map(map) do
    Map.keys(map) |> Enum.sort()
  end

  def b(map) when is_map(map) do
    map |> Enum.map(fn {k, _v} -> k end) |> Enum.sort()
  end
end
```

Change the test configuration:

```elixir
@module_under_test MapOps
@function_a :a
@function_b :b

defp test_data_generator, do: Generators.string_maps(max_length: 5)
```

## What the Universal Tests Check

1. **Deterministic behavior** - Same input always produces same output
2. **Type consistency** - Output type matches expected type
3. **Identical results** - Both functions produce the same results
4. **Edge case handling** - Functions handle empty/minimal inputs
5. **Performance comparison** - Which function is faster
6. **Comprehensive benchmarking** - Detailed performance analysis

## Benefits of Universal Testing

- ✅ **No implementation-specific assumptions**
- ✅ **Works with any two functions with same signature**
- ✅ **Configurable test data generators**
- ✅ **Comprehensive property-based testing**
- ✅ **Performance analysis included**
- ✅ **Easy to adapt for different data types**

Just change the 4 configuration values at the top and you're ready to test any pair of functions!
