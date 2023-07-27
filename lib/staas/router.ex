defmodule Staas.Router do
  alias Staas.SortArray
  use Plug.Router

  plug Plug.Logger
  plug :match

  plug Plug.Parsers,
       parsers: [:json],
       pass:  ["application/json"],
       json_decoder: Jason

  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome to StaS")
  end

  post "/array" do

    # IO.inspect(conn)
    # IO.inspect conn.body_params # Prints JSON POST body

    array =  Map.get(conn.body_params, "list")
    hash_of_array = :crypto.hash(:sha256,array)

    hash_result = Redix.command(:redix, ["GET", hash_of_array])

    IO.inspect(hash_result)

    case hash_result do
      {:ok, nil} ->
        IO.puts("HERE")
        new_array = SortArray.process_array(array)
        conn = assign(conn, :list, new_array)

        Redix.command!(:redix, ["SET", hash_of_array, new_array])

        {:ok, redix_result} = Redix.command(:redix, ["GET", hash_of_array])

        IO.puts("REDIX")
        IO.inspect(redix_result)

        {:ok, result} = Jason.encode(new_array)
        send_resp(conn, 200, result)
      {:ok, array_redis} ->
        IO.puts("Cached")
        IO.inspect(array_redis)

        array_list = :binary.bin_to_list (array_redis)
        {:ok, result} = Jason.encode(array_list)
         send_resp(conn, 200, result)

    end
  end


  match _ do
    send_resp(conn, 404, "There is no route")
  end
end
