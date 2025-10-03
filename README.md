# AB

[![Hex.pm](https://img.shields.io/hexpm/v/ab.svg)](https://hex.pm/packages/ab)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ab/)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/ab.svg)](https://hex.pm/packages/ab)
[![GitHub CI](https://github.com/wende/ab/workflows/Elixir%20CI/badge.svg)](https://github.com/wende/ab/actions)
[![License](https://img.shields.io/hexpm/l/ab.svg)](https://github.com/wende/ab/blob/main/LICENSE)

**Automatically compare two implementations of the same problem with property-based testing and performance benchmarks.**

AB is an Elixir library that makes it effortless to verify that two implementations of the same function behave identically, while also comparing their performance characteristics. Perfect for refactoring, algorithm optimization, and A/B testing different approaches.

## Why AB?

When you have two implementations of the same function:
- **Refactoring** - Ensure your optimized version produces identical results
- **Algorithm comparison** - Compare different algorithms solving the same problem
- **Migration** - Verify new code matches legacy behavior exactly
- **Learning** - Understand tradeoffs between different approaches

AB automatically generates property tests from your typespecs and runs comprehensive comparisons.

## Features

✅ **Automatic property test generation** from function typespecs  
✅ **Side-by-side comparison** of two implementations  
✅ **Performance benchmarking** with detailed statistics  
✅ **Invalid input testing** to verify error handling  
✅ **Type consistency validation** between specs and implementations  
✅ **Zero boilerplate** - just add macros to your tests

## Installation

Add `ab` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:ab, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Define two implementations with identical typespecs

```elixir
defmodule Math do
  # Implementation A: iterative
  @spec factorial_iterative(non_neg_integer()) :: pos_integer()
  def factorial_iterative(n), do: factorial_iter(n, 1)
  
  defp factorial_iter(0, acc), do: acc
  defp factorial_iter(n, acc), do: factorial_iter(n - 1, n * acc)

  # Implementation B: recursive
  @spec factorial_recursive(non_neg_integer()) :: pos_integer()
  def factorial_recursive(0), do: 1
  def factorial_recursive(n), do: n * factorial_recursive(n - 1)
end
```

### 2. Compare them automatically

```elixir
defmodule MathTest do
  use ExUnit.Case
  use ExUnitProperties
  import PropertyGenerator

  # Automatically test both implementations produce identical results
  compare_test {Math, :factorial_iterative}, {Math, :factorial_recursive}

  # Benchmark performance differences
  benchmark_test {Math, :factorial_iterative}, {Math, :factorial_recursive}

  # Test each implementation matches its typespec
  property_test Math, :factorial_iterative
  property_test Math, :factorial_recursive
end
```

That's it! AB will:
- Generate random test data matching your typespec
- Verify both functions produce identical outputs
- Compare performance with detailed statistics
- Validate outputs match the declared return type

## Core Macros

### `compare_test/2` - Verify Identical Behavior

Generates property tests proving two implementations produce identical results:

```elixir
# Basic comparison
compare_test {ModuleA, :function}, {ModuleB, :function}

# With verbose logging
compare_test {ModuleA, :function}, {ModuleB, :function}, verbose: true
```

The macro will:
1. Extract and compare typespecs (must be identical)
2. Generate test data matching the input types
3. Run both functions on the same inputs
4. Assert outputs are identical
5. Validate outputs match the return type

**Example output:**
```
property factorial_iterative and factorial_recursive produce identical results
  ✓ 100 successful comparison runs
✓ factorial_iterative and factorial_recursive produce identical results (1.2ms)
```

### `benchmark_test/2` - Compare Performance

Generates benchmarks comparing two implementations:

```elixir
# Basic benchmark
benchmark_test {ModuleA, :function}, {ModuleB, :function}

# Custom timing
benchmark_test {ModuleA, :function}, {ModuleB, :function},
  time: 5,           # 5 seconds of benchmarking
  memory_time: 2     # 2 seconds of memory profiling
```

**Example output:**
```
=== Benchmarking Math.factorial_iterative vs Math.factorial_recursive ===

Name                           ips        average  deviation         median         99th %
Math.factorial_iterative    1.23 M        0.81 μs   ±612.45%        0.75 μs        1.12 μs
Math.factorial_recursive    0.98 M        1.02 μs   ±587.32%        0.96 μs        1.35 μs

Comparison:
Math.factorial_iterative    1.23 M
Math.factorial_recursive    0.98 M - 1.26x slower +0.21 μs
```

### `property_test/2` - Validate Against Typespec

Automatically generates property tests from function typespecs:

```elixir
# Basic property test
property_test MyModule, :my_function

# With verbose logging
property_test MyModule, :my_function, verbose: true
```

The macro will:
1. Parse the function's `@spec` declaration
2. Generate appropriate test data for all input types
3. Call the function with generated inputs
4. Validate outputs match the declared return type
5. Test type consistency between `@type` and `@spec`

**Supported types:**
- Basic: `integer()`, `float()`, `number()`, `boolean()`, `atom()`, `binary()`, `bitstring()`, `String.t()`, `charlist()`, `nil`
- Collections: `list(type)`, `tuple({type1, type2})`, `map()`, `keyword()`, `keyword(type)`
- Maps: `%{key => value}`, `%{required(:key) => type}`, `%{optional(:key) => type}` (optional fields don't cause validation failures)
- Ranges: `0..100`, `pos_integer()`, `non_neg_integer()`, `neg_integer()`
- Structs: Custom struct types with `@type t :: %__MODULE__{...}`
- Union types: `integer() | String.t()`
- Literals: Specific atom or integer values (e.g., `:ok`, `42`)
- Generic: `any()`, `term()`
- Complex: Nested structures, remote types

**Note:** Maps with optional fields and extra keys are properly handled - only required fields must be present.

### `robust_test/2` - Verify Error Handling

Tests that functions properly reject invalid inputs:

```elixir
# Test invalid input handling
robust_test MyModule, :my_function

# With verbose logging
robust_test MyModule, :my_function, verbose: true
```

This generates inputs that **don't** match the typespec and verifies the function either:
- Raises an appropriate exception
- Has guards that prevent type mismatches

Great for ensuring functions fail gracefully rather than producing garbage output.

## Complete Example

```elixir
defmodule Sum do
  # Implementation A: Enum.sum
  @spec sum_builtin([integer()]) :: integer()
  def sum_builtin(list), do: Enum.sum(list)

  # Implementation B: manual recursion
  @spec sum_recursive([integer()]) :: integer()
  def sum_recursive([]), do: 0
  def sum_recursive([head | tail]), do: head + sum_recursive(tail)
end

defmodule SumTest do
  use ExUnit.Case
  use ExUnitProperties
  import PropertyGenerator

  describe "Sum implementations" do
    # Verify both produce identical results
    compare_test {Sum, :sum_builtin}, {Sum, :sum_recursive}

    # Compare performance
    benchmark_test {Sum, :sum_builtin}, {Sum, :sum_recursive}

    # Validate each against typespec
    property_test Sum, :sum_builtin
    property_test Sum, :sum_recursive

    # Test error handling
    robust_test Sum, :sum_builtin
    robust_test Sum, :sum_recursive
  end
end
```

**Output:**
```
SumTest
  Sum implementations
    property sum_builtin and sum_recursive produce identical results
      ✓ 100 successful comparison runs
    ✓ sum_builtin and sum_recursive produce identical results (1.8ms)
    
    property sum_builtin satisfies its typespec
      ✓ 100 successful property test runs
    ✓ sum_builtin satisfies its typespec (2.1ms)
    ✓ sum_builtin type consistency validation (0.1ms)
    
    property sum_recursive satisfies its typespec
      ✓ 100 successful property test runs
    ✓ sum_recursive satisfies its typespec (2.4ms)
    ✓ sum_recursive type consistency validation (0.1ms)
    
    property sum_builtin properly rejects invalid input
      ✓ 100 successful invalid input test runs
    ✓ sum_builtin properly rejects invalid input (124.3ms)
    
    property sum_recursive properly rejects invalid input
      ✓ 100 successful invalid input test runs
    ✓ sum_recursive properly rejects invalid input (127.8ms)
    
    test benchmark sum_builtin vs sum_recursive
    === Benchmarking Sum.sum_builtin vs Sum.sum_recursive ===
    Name                   ips        average  deviation
    Sum.sum_builtin     1.45 M        0.69 μs   ±652.34%
    Sum.sum_recursive   0.87 M        1.15 μs   ±723.12%
    
    Comparison:
    Sum.sum_builtin     1.45 M
    Sum.sum_recursive   0.87 M - 1.67x slower +0.46 μs
    ✓ benchmark sum_builtin vs sum_recursive (7503.5ms)

Finished in 7.9 seconds
8 properties, 1 test, 0 failures
```

## API Functions

For manual testing and custom scenarios:

### `PropertyGenerator.get_function_spec/2`

Extract typespec information:

```elixir
{:ok, {input_types, output_type}} = 
  PropertyGenerator.get_function_spec(MyModule, :my_function)
```

### `PropertyGenerator.types_equivalent?/2`

Compare two type specifications:

```elixir
PropertyGenerator.types_equivalent?(type1, type2)
# => true | false
```

### `PropertyGenerator.infer_result_type/1`

Get detailed type information from a value:

```elixir
PropertyGenerator.infer_result_type([1, 2, 3])
# => "list(integer())"

PropertyGenerator.infer_result_type(%{name: "Alice", age: 30})
# => "%{age: integer(), name: binary()}"

PropertyGenerator.infer_result_type({:ok, true})
# => "{atom(), boolean()}"

PropertyGenerator.infer_result_type([])
# => "list(term())"  # unknown element type

PropertyGenerator.infer_result_type([1, "a"])
# => "list(term())"  # inconsistent types
```

## Real-World Examples

### Refactoring for Performance

```elixir
# Compare old vs new implementation
compare_test {Parser, :parse_legacy}, {Parser, :parse_optimized}
benchmark_test {Parser, :parse_legacy}, {Parser, :parse_optimized}
```

### Algorithm Comparison

```elixir
# Test different search algorithms
compare_test {Search, :binary_search}, {Search, :interpolation_search}
```

### Data Encoding Comparison

```elixir
# Compare JSON encoding libraries
compare_test {Encoder, :encode_with_jason}, {Encoder, :encode_with_poison}
```

## Dependencies

- **stream_data** - Property-based testing and data generation
- **benchee** - Performance benchmarking
- **ex_unit** - Elixir's built-in test framework

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Credits

Built with ❤️ using:
- [StreamData](https://github.com/whatyouhide/stream_data) by Andrea Leopardi
- [Benchee](https://github.com/bencheeorg/benchee) by Tobias Pfeiffer
- Inspired by QuickCheck and property-based testing

---

**Start comparing your implementations today!** 🚀
