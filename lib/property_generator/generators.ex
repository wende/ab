defmodule PropertyGenerator.Generators do
  @moduledoc """
  Functions for generating valid test data from type specifications.
  """

  use ExUnitProperties

  @doc """
  Creates input generators from type specifications.
  Returns a generator that produces lists of arguments.
  """
  def create_input_generator(input_types) do
    generators = Enum.map(input_types, &type_to_generator/1)

    case generators do
      [single_generator] ->
        StreamData.bind(single_generator, fn value ->
          StreamData.constant([value])
        end)

      multiple_generators ->
        StreamData.bind(StreamData.tuple(List.to_tuple(multiple_generators)), fn tuple ->
          StreamData.constant(Tuple.to_list(tuple))
        end)
    end
  end

  @doc """
  Converts a type specification to a StreamData generator.
  """
  def type_to_generator({:type, _, :integer, []}), do: StreamData.integer()
  def type_to_generator({:type, _, :float, []}), do: StreamData.float()
  def type_to_generator({:type, _, :boolean, []}), do: StreamData.boolean()
  def type_to_generator({:type, _, :binary, []}), do: StreamData.binary()
  def type_to_generator({:type, _, :bitstring, []}), do: StreamData.bitstring()
  def type_to_generator({:type, _, :atom, []}), do: StreamData.atom(:alphanumeric)
  def type_to_generator({:type, _, :string, []}), do: StreamData.string(:printable)
  def type_to_generator({:type, _, :any, []}), do: StreamData.term()
  def type_to_generator({:type, _, :term, []}), do: StreamData.term()
  def type_to_generator({:type, _, nil, []}), do: StreamData.constant(nil)
  def type_to_generator({:atom, _, atom_value}), do: StreamData.constant(atom_value)
  def type_to_generator({:integer, _, int_value}), do: StreamData.constant(int_value)

  def type_to_generator({:type, _, :charlist, []}) do
    StreamData.list_of(StreamData.integer(0..1_114_111))
  end

  def type_to_generator({:type, _, :non_neg_integer, []}) do
    StreamData.integer(0..1000)
  end

  def type_to_generator({:type, _, :pos_integer, []}) do
    StreamData.integer(1..1000)
  end

  def type_to_generator({:type, _, :neg_integer, []}) do
    StreamData.integer(-1000..-1)
  end

  def type_to_generator({:type, _, :range, [min, max]}) do
    min_val = extract_integer_value(min, 0)
    max_val = extract_integer_value(max, 100)
    StreamData.integer(min_val..max_val)
  end

  def type_to_generator({:type, _, :list, [element_type]}) do
    case element_type do
      {:type, _, :tuple, [{:atom, _, key}, value_type]} ->
        # Keyword list
        value_gen = type_to_generator(value_type)
        StreamData.map(value_gen, fn value -> [{key, value}] end)

      _ ->
        # Regular list
        StreamData.list_of(type_to_generator(element_type))
    end
  end

  def type_to_generator({:type, _, :list, []}), do: StreamData.list_of(StreamData.term())

  def type_to_generator({:type, _, :tuple, element_types}) do
    element_generators = Enum.map(element_types, &type_to_generator/1)
    StreamData.tuple(List.to_tuple(element_generators))
  end

  def type_to_generator({:type, _, :map, []}),
    do: StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.term())

  def type_to_generator({:type, _, :map, :any}),
    do: StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.term())

  def type_to_generator({:type, _, :map, field_types}) when is_list(field_types) do
    struct_field = find_struct_field(field_types)

    case struct_field do
      {:type, _, :map_field_exact, [{:atom, _, :__struct__}, {:atom, _, module_name}]} ->
        generate_struct(module_name, field_types)

      nil ->
        generate_map(field_types)
    end
  end

  def type_to_generator({:type, _, :union, types}) do
    generators = Enum.map(types, &type_to_generator/1)
    StreamData.one_of(generators)
  end

  def type_to_generator({:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, []]}) do
    StreamData.string(:printable)
  end

  def type_to_generator({:remote_type, _, [{:atom, _, module}, {:atom, _, :t}, []]}) do
    # Handle remote type references like User.t()
    case Code.ensure_loaded(module) do
      {:module, ^module} ->
        case Code.Typespec.fetch_types(module) do
          {:ok, types} ->
            # Find the @type t definition
            type_def =
              Enum.find_value(types, fn
                {:type, {:t, type_ast, []}} -> type_ast
                _ -> nil
              end)

            case type_def do
              {:type, _, :map, field_types} ->
                # It's a struct type, generate it
                type_to_generator({:type, 0, :map, field_types})

              nil ->
                IO.warn("Could not find @type t for module #{module}, using StreamData.term()")
                StreamData.term()

              other_type ->
                # It's some other type, generate it
                type_to_generator(other_type)
            end

          _ ->
            IO.warn("Could not fetch types for module #{module}, using StreamData.term()")
            StreamData.term()
        end

      _ ->
        IO.warn("Could not load module #{module}, using StreamData.term()")
        StreamData.term()
    end
  end

  def type_to_generator(type) do
    IO.warn("Unknown type #{inspect(type)}, using StreamData.term()")
    StreamData.term()
  end

  # Private helper functions

  defp extract_integer_value({:integer, _, val}, _default), do: val
  defp extract_integer_value(val, _default) when is_integer(val), do: val
  defp extract_integer_value(_val, default), do: default

  defp find_struct_field(field_types) do
    Enum.find(field_types, fn
      {:type, _, :map_field_exact, [{:atom, _, :__struct__}, {:atom, _, _module}]} -> true
      _ -> false
    end)
  end

  defp generate_struct(module_name, field_types) do
    other_fields =
      Enum.reject(field_types, fn
        {:type, _, :map_field_exact, [{:atom, _, :__struct__}, _]} -> true
        _ -> false
      end)

    field_values = Enum.map(other_fields, &generate_field_value/1)

    case field_values do
      [] ->
        StreamData.constant(struct(module_name, %{}))

      _ ->
        StreamData.bind(StreamData.tuple(List.to_tuple(field_values)), fn field_tuple ->
          field_map = Map.new(Tuple.to_list(field_tuple))
          StreamData.constant(struct(module_name, field_map))
        end)
    end
  end

  defp generate_field_value({:type, _, field_type, [{:atom, _, field_name}, value_type]})
       when field_type in [:map_field_exact, :map_field_assoc] do
    value_gen = type_to_generator(value_type)
    StreamData.map(value_gen, fn value -> {field_name, value} end)
  end

  defp generate_map(field_types) do
    field_generators =
      Enum.map(field_types, fn
        {:type, _, field_type, [key_type, value_type]}
        when field_type in [:map_field_exact, :map_field_assoc] ->
          key_gen = type_to_generator(key_type)
          value_gen = type_to_generator(value_type)
          StreamData.tuple({key_gen, value_gen})
      end)

    StreamData.map(
      StreamData.list_of(StreamData.one_of(field_generators), min_length: 1),
      fn pairs -> Map.new(pairs) end
    )
  end
end
