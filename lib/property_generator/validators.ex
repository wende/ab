defmodule PropertyGenerator.Validators do
  @moduledoc """
  Functions for creating type validators from type specifications.
  """

  @doc """
  Creates an output validator from a type specification.
  """
  def create_output_validator(output_type) do
    type_to_validator(output_type)
  end

  @doc """
  Converts a type specification to a validator function.
  """
  def type_to_validator({:type, _, :integer, []}), do: &is_integer/1
  def type_to_validator({:type, _, :float, []}), do: &is_float/1
  def type_to_validator({:type, _, :boolean, []}), do: &is_boolean/1
  def type_to_validator({:type, _, :binary, []}), do: &is_binary/1
  def type_to_validator({:type, _, :bitstring, []}), do: &is_bitstring/1
  def type_to_validator({:type, _, :atom, []}), do: &is_atom/1
  def type_to_validator({:type, _, :string, []}), do: &is_binary/1
  def type_to_validator({:type, _, :list, []}), do: &is_list/1
  def type_to_validator({:type, _, :map, []}), do: &is_map/1
  def type_to_validator({:type, _, nil, []}), do: &is_nil/1
  def type_to_validator({:type, _, :any, []}), do: fn _ -> true end
  def type_to_validator({:type, _, :term, []}), do: fn _ -> true end
  def type_to_validator({:atom, _, atom_value}), do: fn value -> value == atom_value end
  def type_to_validator({:integer, _, int_value}), do: fn value -> value == int_value end

  def type_to_validator({:type, _, :charlist, []}) do
    fn value -> is_list(value) and Enum.all?(value, &is_integer/1) end
  end

  def type_to_validator({:type, _, :non_neg_integer, []}) do
    fn value -> is_integer(value) and value >= 0 end
  end

  def type_to_validator({:type, _, :pos_integer, []}) do
    fn value -> is_integer(value) and value > 0 end
  end

  def type_to_validator({:type, _, :neg_integer, []}) do
    fn value -> is_integer(value) and value < 0 end
  end

  def type_to_validator({:type, _, :range, [min, max]}) do
    min_val = extract_integer_value(min, 0)
    max_val = extract_integer_value(max, 100)

    fn value -> is_integer(value) and value >= min_val and value <= max_val end
  end

  def type_to_validator({:type, _, :list, [element_type]}) do
    case element_type do
      {:type, _, :tuple, [{:atom, _, key}, value_type]} ->
        # Keyword list validator
        value_validator = type_to_validator(value_type)

        fn list ->
          is_list(list) and
            Enum.any?(list, fn
              {^key, value} -> value_validator.(value)
              _ -> false
            end)
        end

      _ ->
        # Regular list validator
        element_validator = type_to_validator(element_type)
        fn list -> is_list(list) and Enum.all?(list, element_validator) end
    end
  end

  def type_to_validator({:type, _, :tuple, element_types}) do
    element_validators = Enum.map(element_types, &type_to_validator/1)
    expected_size = length(element_types)

    fn tuple ->
      is_tuple(tuple) and tuple_size(tuple) == expected_size and
        validate_tuple_elements(tuple, element_validators)
    end
  end

  def type_to_validator({:type, _, :map, field_types}) when is_list(field_types) do
    struct_field = find_struct_field(field_types)

    case struct_field do
      {:type, _, :map_field_exact, [{:atom, _, :__struct__}, {:atom, _, module_name}]} ->
        validate_struct(module_name, field_types)

      nil ->
        validate_map(field_types)
    end
  end

  def type_to_validator({:type, _, :union, types}) do
    validators = Enum.map(types, &type_to_validator/1)
    fn value -> Enum.any?(validators, fn validator -> validator.(value) end) end
  end

  def type_to_validator({:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, []]}) do
    &is_binary/1
  end

  def type_to_validator(_type), do: fn _ -> true end

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

  defp validate_tuple_elements(tuple, validators) do
    validators
    |> Enum.with_index()
    |> Enum.all?(fn {validator, index} -> validator.(elem(tuple, index)) end)
  end

  defp validate_struct(module_name, field_types) do
    other_fields =
      Enum.reject(field_types, fn
        {:type, _, :map_field_exact, [{:atom, _, :__struct__}, _]} -> true
        _ -> false
      end)

    field_validators = Enum.map(other_fields, &create_field_validator/1)

    fn value ->
      is_struct(value, module_name) and
        Enum.all?(field_validators, fn {field_name, validator} ->
          field_value = Map.get(value, field_name)
          validator.(field_value)
        end)
    end
  end

  defp create_field_validator({:type, _, field_type, [{:atom, _, field_name}, value_type]})
       when field_type in [:map_field_exact, :map_field_assoc] do
    value_validator = type_to_validator(value_type)
    {field_name, value_validator}
  end

  defp validate_map(field_types) do
    field_validators =
      Enum.map(field_types, fn
        {:type, _, field_type, [key_type, value_type]}
        when field_type in [:map_field_exact, :map_field_assoc] ->
          key_validator = type_to_validator(key_type)
          value_validator = type_to_validator(value_type)
          {key_validator, value_validator}
      end)

    fn map ->
      is_map(map) and
        Enum.all?(field_validators, fn {key_validator, value_validator} ->
          Enum.any?(map, fn {key, value} ->
            key_validator.(key) and value_validator.(value)
          end)
        end)
    end
  end
end
