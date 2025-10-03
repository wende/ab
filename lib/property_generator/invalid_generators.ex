defmodule PropertyGenerator.InvalidGenerators do
  @moduledoc """
  Functions for generating invalid test data that does NOT match type specifications.
  Used for robustness testing to ensure functions properly reject invalid input.
  """

  use ExUnitProperties

  @doc """
  Creates invalid input generators from type specifications.
  Returns a generator that produces lists of invalid arguments.
  """
  def create_invalid_input_generator(input_types) do
    invalid_generators = Enum.map(input_types, &type_to_invalid_generator/1)

    case invalid_generators do
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
  Converts a type specification to an invalid StreamData generator.
  """
  def type_to_invalid_generator({:type, _, :integer, []}) do
    non_integer_types()
  end

  def type_to_invalid_generator({:type, _, :float, []}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.float()),
      generic_map()
    ])
  end

  def type_to_invalid_generator({:type, _, :boolean, []}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.list_of(StreamData.atom(:alphanumeric))
    ])
  end

  def type_to_invalid_generator({:type, _, :binary, []}) do
    non_binary_types()
  end

  def type_to_invalid_generator({:type, _, :bitstring, []}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.atom(:alphanumeric),
      generic_map()
    ])
  end

  def type_to_invalid_generator({:type, _, :atom, []}) do
    non_atom_types()
  end

  def type_to_invalid_generator({:type, _, :string, []}) do
    non_string_types()
  end

  def type_to_invalid_generator({:type, _, :list, _}) do
    non_list_types()
  end

  def type_to_invalid_generator({:type, _, :tuple, _}) do
    non_tuple_types()
  end

  def type_to_invalid_generator({:type, _, :map, _}) do
    non_map_types()
  end

  def type_to_invalid_generator({:type, _, nil, []}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term())
    ])
  end

  def type_to_invalid_generator({:atom, _, atom_value}) do
    StreamData.one_of([
      StreamData.atom(:alphanumeric),
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable)
    ])
    |> StreamData.filter(fn value -> value != atom_value end)
  end

  def type_to_invalid_generator({:integer, _, int_value}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric)
    ])
    |> StreamData.filter(fn value -> value != int_value end)
  end

  def type_to_invalid_generator({:type, _, :charlist, []}) do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      generic_map()
    ])
  end

  def type_to_invalid_generator({:type, _, :any, []}), do: StreamData.term()
  def type_to_invalid_generator({:type, _, :term, []}), do: StreamData.term()

  def type_to_invalid_generator({:type, _, :range, _}) do
    StreamData.one_of([
      StreamData.integer(-1000..-1),
      StreamData.integer(1001..2000),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric)
    ])
  end

  def type_to_invalid_generator({:type, _, :non_neg_integer, []}) do
    StreamData.one_of([
      StreamData.integer(-1000..-1),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric)
    ])
  end

  def type_to_invalid_generator({:type, _, :pos_integer, []}) do
    StreamData.one_of([
      StreamData.integer(-1000..0),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric)
    ])
  end

  def type_to_invalid_generator({:type, _, :neg_integer, []}) do
    StreamData.one_of([
      StreamData.integer(0..1000),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric)
    ])
  end

  def type_to_invalid_generator({:type, _, :union, _types}) do
    generic_invalid_types()
  end

  def type_to_invalid_generator({:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, []]}) do
    non_string_types()
  end

  def type_to_invalid_generator({:remote_type, _, [{:atom, _, _module}, {:atom, _, :t}, []]}) do
    # For custom types like User.t(), generate invalid types (anything except the struct itself)
    # This will generate non-struct types that should fail the function
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term()),
      StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.term())
    ])
  end

  def type_to_invalid_generator(type) do
    IO.warn("Unknown type #{inspect(type)}, using generic invalid generator")
    generic_invalid_types()
  end

  # Private helper functions for common invalid type generators

  defp non_integer_types do
    StreamData.one_of([
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.integer()),
      generic_map()
    ])
  end

  defp non_binary_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term()),
      generic_map()
    ])
  end

  defp non_atom_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.list_of(StreamData.term()),
      generic_map()
    ])
  end

  defp non_string_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term()),
      generic_map()
    ])
  end

  defp non_list_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      generic_map()
    ])
  end

  defp non_tuple_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term()),
      generic_map()
    ])
  end

  defp non_map_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term())
    ])
  end

  defp generic_invalid_types do
    StreamData.one_of([
      StreamData.integer(),
      StreamData.float(),
      StreamData.string(:printable),
      StreamData.atom(:alphanumeric),
      StreamData.list_of(StreamData.term()),
      generic_map()
    ])
  end

  defp generic_map do
    StreamData.map_of(StreamData.atom(:alphanumeric), StreamData.term())
  end
end
