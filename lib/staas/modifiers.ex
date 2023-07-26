defmodule Staas.Modifiers do
  def to_list(input) do
    input
    |> String.slice(1..-2)
    |> String.replace(" ", "")
    |> String.split(",")
    |> Enum.map(fn x -> String.to_integer(x) end)
  end

  def to_string(list) do
    "[" <> Enum.join(list, ",") <> "]"
  end
end
