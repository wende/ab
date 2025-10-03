defmodule PropertyGenerator do
  @moduledoc """
  A macro-based property testing generator that analyzes function typespecs
  to automatically generate appropriate test data and output validators.

  ## Usage

      defmodule MyModuleTest do
        use ExUnit.Case
        use ExUnitProperties
        import PropertyGenerator

        # Generate property test for a function with typespec
        property_test MyModule, :my_function
      end
  """

  use ExUnitProperties
  import ExUnit.Assertions

  alias PropertyGenerator.{TypeParser, Generators, Validators, InvalidGenerators}

  @doc """
  Macro that generates property testing utilities for a function based on its typespec.

  Takes a module and function name, analyzes the typespec, and generates:
  1. Input generators based on the function's parameter types
  2. Output validators based on the function's return type
  3. A complete property test

  ## Example

      # For a function with spec: @spec sort_list([integer()]) :: [integer()]
      property_test MyModule, :sort_list

      # With verbose output
      property_test MyModule, :sort_list, verbose: true

  This will generate a property test that validates the function behavior.
  """
  defmacro property_test(module, function_name, opts \\ []) do
    quoted_test = property_test_quoted(module, function_name, opts)
    quote do: unquote(quoted_test)
  end

  defp property_test_quoted(module, function_name, opts) do
    quote do
      property unquote("#{function_name} satisfies its typespec") do
        PropertyGenerator.run_property_test(
          unquote(module),
          unquote(function_name),
          unquote(opts)
        )
      end

      property unquote("#{function_name} type consistency validation") do
        PropertyGenerator.validate_type_consistency(unquote(module), unquote(function_name))
      end
    end
  end

  @doc false
  def run_property_test(module, function_name, opts) do
    case get_function_spec(module, function_name) do
      {:ok, {input_types, output_type}} ->
        run_property_test_with_spec(module, function_name, input_types, output_type, opts)

      {:error, reason} ->
        flunk("Could not generate property test: #{reason}")
    end
  end

  defp run_property_test_with_spec(module, function_name, input_types, output_type, opts) do
    input_generator = create_input_generator_runtime(input_types)
    output_validator = create_output_validator_runtime(output_type)
    verbose = Keyword.get(opts, :verbose, false)

    # Track successful runs
    agent = start_counter()

    try do
      check all(input <- input_generator) do
        result = apply(module, function_name, input)
        increment_counter(agent)
        maybe_log_verbose(verbose, input, result)
        validate_output_or_flunk(result, output_validator, output_type)
      end

      count = get_counter(agent)
      IO.puts("  ✓ #{count} successful property test runs")
    after
      stop_counter(agent)
    end
  end

  defp maybe_log_verbose(true, input, result) do
    IO.puts("Input: #{inspect(input)} -> Output: #{inspect(result)}")
  end

  defp maybe_log_verbose(false, _input, _result), do: :ok

  defp validate_output_or_flunk(result, output_validator, output_type) do
    if output_validator.(result) do
      :ok
    else
      result_type = infer_result_type(result)

      flunk(
        "Output type validation failed: function returned #{inspect(result)} (#{result_type}) but typespec declares return type as #{inspect(output_type)}"
      )
    end
  end

  @doc """
  Macro that compares two functions with identical typespecs using the same generated test data.

  Takes two module/function pairs, verifies their typespecs are identical, and if so,
  runs both functions on the same generated inputs to ensure they produce identical outputs.

  ## Example

      # Compare two sorting implementations
      compare_test {AB, :a}, {AB, :b}

      # With verbose output
      compare_test {AB, :a}, {AB, :b}, verbose: true

  This will generate a property test that validates both functions behave identically.
  """
  defmacro compare_test({module1, function1}, {module2, function2}, opts \\ []) do
    quoted_test = compare_test_quoted(module1, function1, module2, function2, opts)
    quote do: unquote(quoted_test)
  end

  defp compare_test_quoted(module1, function1, module2, function2, opts) do
    quote do
      property unquote("#{function1} and #{function2} produce identical results") do
        PropertyGenerator.run_compare_test(
          unquote(module1),
          unquote(function1),
          unquote(module2),
          unquote(function2),
          unquote(opts)
        )
      end
    end
  end

  @doc false
  def run_compare_test(module1, function1, module2, function2, opts) do
    with {:ok, spec1} <- get_function_spec(module1, function1),
         {:ok, spec2} <- get_function_spec(module2, function2) do
      run_compare_test_with_specs(module1, function1, module2, function2, spec1, spec2, opts)
    else
      {:error, reason} ->
        flunk("Could not get typespec: #{reason}")
    end
  end

  defp run_compare_test_with_specs(
         module1,
         function1,
         module2,
         function2,
         {input_types1, output_type1},
         {input_types2, output_type2},
         opts
       ) do
    unless types_equivalent?(input_types1, input_types2) and
             types_equivalent?(output_type1, output_type2) do
      flunk(
        "Function typespecs do not match: #{module1}.#{function1} has #{inspect({input_types1, output_type1})}, #{module2}.#{function2} has #{inspect({input_types2, output_type2})}"
      )
    end

    run_comparison_check(module1, function1, module2, function2, input_types1, output_type1, opts)
  end

  defp run_comparison_check(
         module1,
         function1,
         module2,
         function2,
         input_types,
         output_type,
         opts
       ) do
    input_generator = create_input_generator_runtime(input_types)
    output_validator = create_output_validator_runtime(output_type)
    verbose = Keyword.get(opts, :verbose, false)

    # Track successful runs
    agent = start_counter()

    try do
      check all(input <- input_generator) do
        result1 = apply(module1, function1, input)
        result2 = apply(module2, function2, input)
        increment_counter(agent)

        maybe_log_comparison(
          verbose,
          input,
          module1,
          function1,
          result1,
          module2,
          function2,
          result2
        )

        assert_outputs_valid(
          module1,
          function1,
          result1,
          module2,
          function2,
          result2,
          output_validator
        )

        assert_results_equal(result1, result2)
      end

      count = get_counter(agent)
      IO.puts("  ✓ #{count} successful comparison runs")
    after
      stop_counter(agent)
    end
  end

  defp maybe_log_comparison(true, input, module1, function1, result1, module2, function2, result2) do
    IO.puts("Input: #{inspect(input)}")
    IO.puts("  #{module1}.#{function1}: #{inspect(result1)}")
    IO.puts("  #{module2}.#{function2}: #{inspect(result2)}")
  end

  defp maybe_log_comparison(false, _input, _m1, _f1, _r1, _m2, _f2, _r2), do: :ok

  defp assert_outputs_valid(module1, function1, result1, module2, function2, result2, validator) do
    assert validator.(result1),
           "#{module1}.#{function1} output #{inspect(result1)} does not match expected type"

    assert validator.(result2),
           "#{module2}.#{function2} output #{inspect(result2)} does not match expected type"
  end

  defp assert_results_equal(result1, result2) do
    assert result1 == result2,
           "Functions produced different results: #{inspect(result1)} != #{inspect(result2)}"
  end

  @doc """
  Macro that benchmarks two functions with identical typespecs using Benchee.

  Takes two module/function pairs, verifies their typespecs are identical, and if so,
  runs a benchmark comparison using generated test data.

  ## Example

      # Benchmark two sorting implementations
      benchmark_test {AB, :a}, {AB, :b}

      # With custom options
      benchmark_test {AB, :a}, {AB, :b}, time: 5, memory_time: 2

  This will generate a benchmark test that compares performance of both functions.
  """
  defmacro benchmark_test({module1, function1}, {module2, function2}, opts \\ []) do
    quoted_test = benchmark_test_quoted(module1, function1, module2, function2, opts)
    quote do: unquote(quoted_test)
  end

  defp benchmark_test_quoted(module1, function1, module2, function2, opts) do
    quote do
      test unquote("benchmark #{function1} vs #{function2}") do
        PropertyGenerator.run_benchmark_test(
          unquote(module1),
          unquote(function1),
          unquote(module2),
          unquote(function2),
          unquote(opts)
        )
      end
    end
  end

  @doc false
  def run_benchmark_test(module1, function1, module2, function2, opts) do
    with {:ok, spec1} <- get_function_spec(module1, function1),
         {:ok, spec2} <- get_function_spec(module2, function2) do
      run_benchmark_test_with_specs(module1, function1, module2, function2, spec1, spec2, opts)
    else
      {:error, reason} ->
        flunk("Could not get typespec: #{reason}")
    end
  end

  defp run_benchmark_test_with_specs(
         module1,
         function1,
         module2,
         function2,
         {input_types1, output_type1},
         {input_types2, output_type2},
         opts
       ) do
    unless types_equivalent?(input_types1, input_types2) and
             types_equivalent?(output_type1, output_type2) do
      flunk(
        "Function typespecs do not match: #{module1}.#{function1} has #{inspect({input_types1, output_type1})}, #{module2}.#{function2} has #{inspect({input_types2, output_type2})}"
      )
    end

    run_benchee(module1, function1, module2, function2, input_types1, opts)
  end

  defp run_benchee(module1, function1, module2, function2, input_types, opts) do
    input_generator = create_input_generator_runtime(input_types)
    test_inputs = Enum.take(input_generator, 100)

    time = Keyword.get(opts, :time, 3)
    memory_time = Keyword.get(opts, :memory_time, 1)

    IO.puts("\n=== Benchmarking #{module1}.#{function1} vs #{module2}.#{function2} ===")

    Benchee.run(
      %{
        "#{module1}.#{function1}" => fn ->
          Enum.each(test_inputs, fn input ->
            apply(module1, function1, input)
          end)
        end,
        "#{module2}.#{function2}" => fn ->
          Enum.each(test_inputs, fn input ->
            apply(module2, function2, input)
          end)
        end
      },
      time: time,
      memory_time: memory_time,
      formatters: [Benchee.Formatters.Console]
    )
  end

  @doc """
  Macro that validates struct type definitions against function typespecs.

  This catches inconsistencies where @type definitions don't match @spec definitions.

  ## Example

      # This will fail if @type t :: %AB{a: atom()} but @spec expects integer()
      validate_struct_consistency AB
  """
  defmacro validate_struct_consistency(module) do
    module_name = extract_module_name(module)
    quoted_test = validate_struct_consistency_quoted(module, module_name)
    quote do: unquote(quoted_test)
  end

  defp extract_module_name(module) do
    case module do
      {:__aliases__, _, [name]} -> name
      name when is_atom(name) -> name
      _ -> module
    end
  end

  defp validate_struct_consistency_quoted(module, module_name) do
    quote do
      test unquote("#{module_name} struct type consistency") do
        PropertyGenerator.run_struct_consistency_validation(unquote(module))
      end
    end
  end

  @doc false
  def run_struct_consistency_validation(module) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        validate_module_struct_consistency(module)

      _ ->
        flunk("Could not load module #{module}")
    end
  end

  defp validate_module_struct_consistency(module) do
    with {:ok, types} <- Code.Typespec.fetch_types(module),
         true <- has_struct_type?(types),
         {:ok, specs} <- Code.Typespec.fetch_specs(module) do
      validate_each_spec(module, specs)
    else
      _ -> :ok
    end
  end

  defp has_struct_type?(types) do
    Enum.any?(types, fn
      {:type, {:t, _, []}} -> true
      _ -> false
    end)
  end

  defp validate_each_spec(module, specs) do
    Enum.each(specs, fn {{function_name, _arity}, [spec | _]} ->
      validate_spec_against_type(module, function_name, spec)
    end)
  end

  defp validate_spec_against_type(module, function_name, spec) do
    case parse_spec(spec) do
      {:ok, {[_input_type], _output_type}} ->
        validate_function_with_generated_struct(module, function_name)

      _ ->
        :ok
    end
  end

  defp validate_function_with_generated_struct(module, function_name) do
    case create_struct_from_type_definition(module) do
      nil ->
        :ok

      gen ->
        test_struct_against_function(module, function_name, gen)
    end
  end

  defp test_struct_against_function(module, function_name, gen) do
    test_input = gen |> Enum.take(1) |> List.first()

    try do
      apply(module, function_name, [test_input])
    rescue
      e ->
        flunk(
          "Type inconsistency detected: @type definition creates structs that don't work with @spec for #{function_name}/1. Error: #{inspect(e)}"
        )
    end
  end

  @doc """
  Macro that generates robustness tests for a function based on its typespec.

  Takes a module and function name, analyzes the typespec, and generates:
  1. Invalid input generators that create data NOT matching the function's parameter types
  2. Tests that verify functions either raise errors or return invalid output when given invalid input
  3. Ensures functions fail gracefully rather than silently accepting wrong input types

  ## Example

      # For a function with spec: @spec process(integer()) :: string()
      robust_test MyModule, :process

      # With verbose output
      robust_test MyModule, :process, verbose: true

  This will generate tests that verify the function properly rejects invalid input.
  """
  defmacro robust_test(module, function_name, opts \\ []) do
    quoted_test = robust_test_quoted(module, function_name, opts)
    quote do: unquote(quoted_test)
  end

  defp robust_test_quoted(module, function_name, opts) do
    quote do
      property unquote("#{function_name} properly rejects invalid input") do
        PropertyGenerator.run_robust_test(
          unquote(module),
          unquote(function_name),
          unquote(opts)
        )
      end
    end
  end

  @doc false
  def run_robust_test(module, function_name, opts) do
    case get_function_spec(module, function_name) do
      {:ok, {input_types, _output_type}} ->
        run_robust_test_with_spec(module, function_name, input_types, opts)

      {:error, reason} ->
        flunk("Could not generate robust test: #{reason}")
    end
  end

  defp run_robust_test_with_spec(module, function_name, input_types, opts) do
    invalid_input_generator = create_invalid_input_generator_runtime(input_types)
    verbose = Keyword.get(opts, :verbose, false)

    # Track successful runs
    agent = start_counter()

    try do
      check all(invalid_input <- invalid_input_generator) do
        test_invalid_input(module, function_name, invalid_input, verbose)
        increment_counter(agent)
      end

      count = get_counter(agent)
      IO.puts("  ✓ #{count} successful invalid input test runs")
    after
      stop_counter(agent)
    end
  end

  defp test_invalid_input(module, function_name, invalid_input, verbose) do
    try do
      result = apply(module, function_name, invalid_input)
      handle_unexpected_success(invalid_input, result, verbose)
    rescue
      e in [ExUnit.AssertionError] ->
        reraise e, __STACKTRACE__

      e ->
        handle_expected_exception(invalid_input, e, verbose)
    end
  end

  defp handle_unexpected_success(invalid_input, result, verbose) do
    if verbose do
      IO.puts("Invalid input: #{inspect(invalid_input)} -> Output: #{inspect(result)}")
    end

    flunk(
      "Function accepted invalid input #{inspect(invalid_input)} without validation and returned #{inspect(result)}. Expected function to either raise an exception or validate input types."
    )
  end

  defp handle_expected_exception(invalid_input, exception, true) do
    IO.puts(
      "Invalid input: #{inspect(invalid_input)} -> Exception: #{Exception.message(exception)} ✓"
    )
  end

  defp handle_expected_exception(_invalid_input, _exception, false), do: :ok

  # Public API functions delegating to submodules

  @doc "Extracts the typespec for a given function."
  defdelegate get_function_spec(module, function_name), to: TypeParser

  @doc "Compares two type specifications for equivalence."
  defdelegate types_equivalent?(type1, type2), to: TypeParser

  @doc "Creates a struct generator from @type definition."
  defdelegate create_struct_from_type_definition(module), to: TypeParser

  @doc "Parses a spec into input and output types."
  defdelegate parse_spec(spec), to: TypeParser, as: :parse_spec

  @doc "Creates input generators from type specifications."
  def create_input_generator_runtime(input_types) do
    Generators.create_input_generator(input_types)
  end

  @doc "Creates output validators from type specifications."
  def create_output_validator_runtime(output_type) do
    Validators.create_output_validator(output_type)
  end

  @doc "Creates invalid input generators from type specifications."
  def create_invalid_input_generator_runtime(input_types) do
    InvalidGenerators.create_invalid_input_generator(input_types)
  end

  @doc """
  Validates type consistency between @type definitions and @spec definitions.
  """
  def validate_type_consistency(module, function_name) do
    try do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          type_def =
            Enum.find_value(types, fn
              {:type, {:t, type_ast, []}} -> type_ast
              _ -> nil
            end)

          case type_def do
            {:type, _, :map, field_types} ->
              validate_struct_field_consistency(module, function_name, field_types)

            _ ->
              :ok
          end

        _ ->
          :ok
      end
    rescue
      e ->
        raise e
    end
  end

  @doc """
  Infers a human-readable type name from a result value.
  """
  def infer_result_type(result) do
    cond do
      is_integer(result) -> "integer"
      is_atom(result) -> "atom"
      is_binary(result) -> "binary/string"
      is_list(result) -> "list"
      is_map(result) -> "map"
      is_tuple(result) -> "tuple"
      true -> "#{inspect(:erlang.element(1, result))}"
    end
  end

  # Private helper functions

  defp validate_struct_field_consistency(module, function_name, type_field_types) do
    with {:ok, {[spec_input_type], spec_output_type}} <- get_function_spec(module, function_name),
         type_fields when not is_nil(type_fields) <-
           TypeParser.extract_struct_fields(type_field_types),
         spec_fields when not is_nil(spec_fields) <-
           extract_struct_fields_from_spec(spec_input_type) do
      validate_all_fields(module, function_name, type_fields, spec_fields, spec_output_type)
    else
      _ -> :ok
    end
  end

  defp validate_all_fields(module, function_name, type_fields, spec_fields, spec_output_type) do
    Enum.each(type_fields, fn {field_name, type_field_type} ->
      validate_single_field(
        module,
        function_name,
        field_name,
        type_field_type,
        spec_fields,
        spec_output_type
      )
    end)
  end

  defp validate_single_field(
         module,
         function_name,
         field_name,
         type_field_type,
         spec_fields,
         spec_output_type
       ) do
    case Map.get(spec_fields, field_name) do
      nil ->
        :ok

      ^type_field_type ->
        :ok

      spec_field_type ->
        validate_field_type_mismatch(
          module,
          function_name,
          field_name,
          type_field_type,
          spec_field_type,
          spec_output_type
        )
    end
  end

  defp validate_field_type_mismatch(
         module,
         function_name,
         field_name,
         type_field_type,
         spec_field_type,
         spec_output_type
       ) do
    if types_equivalent?(type_field_type, spec_field_type) do
      :ok
    else
      test_field_inconsistency(
        module,
        function_name,
        field_name,
        type_field_type,
        spec_field_type,
        spec_output_type
      )
    end
  end

  defp test_field_inconsistency(
         module,
         function_name,
         field_name,
         type_field_type,
         spec_field_type,
         spec_output_type
       ) do
    case create_struct_from_type_definition(module) do
      nil ->
        :ok

      type_generator ->
        test_struct = type_generator |> Enum.take(1) |> List.first()

        try do
          result = apply(module, function_name, [test_struct])
          output_validator = create_output_validator_runtime(spec_output_type)

          unless output_validator.(result) do
            raise_type_inconsistency_error(
              module,
              field_name,
              type_field_type,
              spec_field_type,
              "This causes function to return invalid output."
            )
          end
        rescue
          e ->
            raise_type_inconsistency_error(
              module,
              field_name,
              type_field_type,
              spec_field_type,
              "Error: #{inspect(e)}"
            )
        end
    end
  end

  defp raise_type_inconsistency_error(
         module,
         field_name,
         type_field_type,
         spec_field_type,
         suffix
       ) do
    raise "Type inconsistency: @type #{module}.t defines field :#{field_name} as #{inspect(type_field_type)} but @spec expects #{inspect(spec_field_type)}. #{suffix}"
  end

  defp extract_struct_fields_from_spec({:type, _, :map, field_types}) do
    TypeParser.extract_struct_fields(field_types)
  end

  defp extract_struct_fields_from_spec(_), do: nil

  # Counter helpers for tracking successful test runs
  defp start_counter do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    agent
  end

  defp increment_counter(agent) do
    Agent.update(agent, &(&1 + 1))
  end

  defp get_counter(agent) do
    Agent.get(agent, & &1)
  end

  defp stop_counter(agent) do
    Agent.stop(agent)
  end
end
