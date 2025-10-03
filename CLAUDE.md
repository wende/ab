# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **AB** - an Elixir library for automatic comparison of implementations using property-based testing and performance benchmarks. The library generates property tests from function typespecs to verify that two implementations produce identical results and compare their performance characteristics.

## Core Architecture

### Main Components

- **PropertyGenerator** (`lib/property_generator.ex`) - The main module providing macros for property testing:
  - `property_test/2,3` - Validates functions against their typespecs
  - `compare_test/2,3` - Compares two implementations for identical behavior  
  - `benchmark_test/2,3` - Performance benchmarks between implementations
  - `robust_test/2,3` - Tests error handling with invalid inputs

- **Sub-modules** (`lib/property_generator/`):
  - `TypeParser` - Extracts and parses Elixir typespecs
  - `Generators` - Creates test data generators from type specifications
  - `Validators` - Creates output validators from return types  
  - `InvalidGenerators` - Creates invalid input generators for robustness testing

### Key Features

- Automatic test data generation from `@spec` declarations
- Side-by-side comparison of different implementations
- Performance benchmarking with Benchee integration
- Type consistency validation between `@type` and `@spec`
- Invalid input testing for error handling validation

## Development Commands

### Testing
```bash
# Run all tests with trace output (configured as default alias)
mix test

# Run specific test file
mix test test/filename_test.exs

# Run with verbose property test output
# Tests support `verbose: true` option in macros
```

### Code Quality
```bash
# Format code
mix format

# Static analysis (if Credo is available)
mix credo

# Type checking (if Dialyzer is available)  
mix dialyxir
```

### Documentation
```bash
# Generate docs
mix docs

# View docs locally
open doc/index.html
```

### Dependencies
```bash
# Fetch dependencies
mix deps.get

# Update dependencies
mix deps.update --all
```

## Key Dependencies

- **stream_data** - Property-based testing and data generation
- **benchee** - Performance benchmarking framework
- **ex_unit** - Elixir's built-in testing framework

## Important Implementation Details

### Typespec Support
The library supports extensive Elixir type system features:
- Basic types: `integer()`, `float()`, `boolean()`, `atom()`, `binary()`, etc.
- Collections: `list(type)`, `map()`, `tuple()`, `keyword()`
- Complex maps: `%{required(:key) => type}`, `%{optional(:key) => type}`
- Union types: `integer() | String.t()`
- Custom structs with `@type t :: %__MODULE__{...}`
- Function types: `(arg_type -> return_type)`
- Ranges: `0..100`, `pos_integer()`, `non_neg_integer()`

### Test Configuration
ExUnit is configured in `test/test_helper.exs` with:
- Trace mode enabled for detailed output
- Deterministic test ordering (seed: 0)
- Property-based testing support

### Macro System
The library uses Elixir macros extensively to generate tests at compile time. All main functionality is exposed through macros that expand to property tests using ExUnitProperties.

## Testing the Library Itself
The repository includes "meta-tests" that test the PropertyGenerator against itself, validating that the type parsing and generation logic works correctly on complex real-world typespecs.