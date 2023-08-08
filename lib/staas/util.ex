defmodule Staas.Util do
  @moduledoc "
  Operations with lists
  "
  def is_valid_list(list) do
    is_list(list) and is_list_of_ints(list)
  end

  defp is_list_of_ints(list) do
    list
    |> Enum.map(&is_integer(&1))
    |> Enum.reduce(fn x, acc -> x and acc end)
  end
end
