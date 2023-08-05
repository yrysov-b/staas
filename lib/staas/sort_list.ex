defmodule Staas.SortList do
  @moduledoc "
  Sorts list
  "
  def process_list(list) do
    new_list = Enum.sort(list, :asc)
    new_list
  end
end
