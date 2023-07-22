defmodule Staas.Sort do

  def sort(list) do
    #Convert bitstring to list
    IO.inspect(list)

    new_list =
    list
    |>
    String.trim( ":")
    |>
    String.trim("[")
    |>
    String.trim("]")
    |>
    String.split(",")


    IO.inspect(new_list)

    result = Enum.map(new_list, fn x -> String.to_integer(x) end)

    IO.inspect(result)


    # #Sort it
    # result = Enum.sort(new_list)
    # #Send it
    # result

    list
  end

end
