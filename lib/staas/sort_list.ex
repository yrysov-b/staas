defmodule Staas.SortList do
  def process_list(list) do
    new_list = Enum.sort(list, :asc)
    new_list
  end
end
