defmodule Staas.SortArray do

  def process_array(array) do
    new_array = Enum.sort(array, :asc)
    new_array
  end

end
