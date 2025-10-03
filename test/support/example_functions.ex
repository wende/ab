defmodule ExampleFunctions do
  @moduledoc """
  Example functions with various typespecs to demonstrate PropertyGenerator capabilities.
  """

  defmodule User do
    @moduledoc "Example struct for testing struct type support"
    defstruct [:name, :age, :email]

    @type t :: %__MODULE__{
            name: String.t(),
            age: non_neg_integer(),
            email: String.t()
          }
  end

  @doc "Simple integer addition"
  @spec add_integers(integer(), integer()) :: integer()
  def add_integers(a, b), do: a + b

  @doc "String concatenation"
  @spec concat_strings(String.t(), String.t()) :: String.t()
  def concat_strings(a, b), do: a <> b

  @doc "List length calculation"
  @spec list_length([any()]) :: non_neg_integer()
  def list_length(list), do: length(list)

  @doc "Map key extraction"
  @spec get_keys(map()) :: [atom()]
  def get_keys(map), do: Map.keys(map)

  @doc "Boolean negation"
  @spec negate(boolean()) :: boolean()
  def negate(bool), do: not bool

  @doc "Tuple creation"
  @spec make_tuple(integer(), String.t()) :: {integer(), String.t()}
  def make_tuple(num, str), do: {num, str}

  @doc "Union type handling"
  @spec process_value(integer() | String.t()) :: String.t()
  def process_value(value) when is_integer(value), do: Integer.to_string(value)
  def process_value(value) when is_binary(value), do: value

  @doc "Range validation"
  @spec validate_percentage(0..100) :: boolean()
  def validate_percentage(value), do: value >= 0 and value <= 100

  @doc "List filtering"
  @spec filter_positive([integer()]) :: [integer()]
  def filter_positive(list), do: Enum.filter(list, &(&1 > 0))

  @doc "Atom to string conversion"
  @spec atom_to_string(atom()) :: String.t()
  def atom_to_string(atom), do: Atom.to_string(atom)

  @doc "Struct handling - returns the user's name"
  @spec get_user_name(User.t()) :: String.t()
  def get_user_name(%User{name: name}), do: name

  @doc "Struct creation"
  @spec create_user(String.t(), non_neg_integer()) :: User.t()
  def create_user(name, age), do: %User{name: name, age: age, email: "#{name}@example.com"}
end
