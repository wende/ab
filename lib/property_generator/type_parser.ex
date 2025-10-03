defmodule PropertyGenerator.TypeParser do
  @moduledoc """
  Functions for parsing and extracting type specifications from modules.
  """

  @doc """
  Extracts the typespec for a given function.
  Returns {:ok, {input_types, output_type}} or {:error, reason}.
  """
  @spec get_function_spec(module(), atom()) :: {:ok, {[any()], any()}} | {:error, String.t()}
  def get_function_spec(module, function_name) do
    try do
      Code.ensure_loaded(module)

      case Code.Typespec.fetch_specs(module) do
        {:ok, specs} ->
          case find_function_spec(specs, function_name) do
            nil -> {:error, "No typespec found for #{function_name}"}
            spec -> parse_spec(spec)
          end

        :error ->
          {:error, "No typespecs available for module #{module}"}
      end
    rescue
      e -> {:error, "Error fetching typespecs: #{inspect(e)}"}
    end
  end

  @doc """
  Compares two type specifications for equivalence, ignoring metadata like line numbers.
  """
  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?({:type, _, name1, args1}, {:type, _, name2, args2}) do
    name1 == name2 and types_equivalent?(args1, args2)
  end

  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?({:integer, _, value1}, {:integer, _, value2}) do
    value1 == value2
  end

  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?({:atom, _, value1}, {:atom, _, value2}) do
    value1 == value2
  end

  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?(
        {:remote_type, _, [{:atom, _, mod1}, {:atom, _, name1}, args1]},
        {:remote_type, _, [{:atom, _, mod2}, {:atom, _, name2}, args2]}
      ) do
    mod1 == mod2 and name1 == name2 and types_equivalent?(args1, args2)
  end

  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?(type1, type2) when is_list(type1) and is_list(type2) do
    length(type1) == length(type2) and
      Enum.zip(type1, type2) |> Enum.all?(fn {t1, t2} -> types_equivalent?(t1, t2) end)
  end

  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?(type1, type2) when type1 == type2, do: true
  @spec types_equivalent?(any(), any()) :: boolean()
  def types_equivalent?(_, _), do: false

  @doc """
  Creates a struct generator based on the module's @type definition rather than @spec.
  """
  @spec create_struct_from_type_definition(module()) :: any() | nil
  def create_struct_from_type_definition(module) do
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
              PropertyGenerator.Generators.type_to_generator({:type, 0, :map, field_types})

            _ ->
              nil
          end

        _ ->
          nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Extracts struct fields from field types.
  """
  @spec extract_struct_fields([any()]) :: %{atom() => any()} | nil
  def extract_struct_fields(field_types) do
    try do
      field_types
      |> Enum.reject(fn
        {:type, _, :map_field_exact, [{:atom, _, :__struct__}, _]} -> true
        _ -> false
      end)
      |> Enum.map(fn
        {:type, _, :map_field_exact, [{:atom, _, field_name}, field_type]} ->
          {field_name, field_type}

        {:type, _, :map_field_assoc, [{:atom, _, field_name}, field_type]} ->
          {field_name, field_type}

        _ ->
          nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()
    rescue
      _ -> nil
    end
  end

  @doc """
  Parses a spec AST into input and output types.
  """
  @spec parse_spec(any()) :: {:ok, {[any()], any()}} | {:error, String.t()}
  def parse_spec({:type, _, :fun, [{:type, _, :product, input_types}, output_type]}) do
    {:ok, {input_types, output_type}}
  end

  @spec parse_spec(any()) :: {:ok, {[any()], any()}} | {:error, String.t()}
  def parse_spec({:type, _, :fun, [input_type, output_type]}) when not is_list(input_type) do
    {:ok, {[input_type], output_type}}
  end

  @spec parse_spec(any()) :: {:ok, {[any()], any()}} | {:error, String.t()}
  def parse_spec(_), do: {:error, "Unsupported spec format"}

  # Private functions

  @spec find_function_spec([any()], atom()) :: any() | nil
  defp find_function_spec(specs, function_name) do
    Enum.find_value(specs, fn
      {{^function_name, _arity}, [spec | _]} -> spec
      _ -> nil
    end)
  end
end
