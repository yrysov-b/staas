defmodule Staas.Router do
  alias Staas.SortList
  alias Staas.Util
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome to StaaS")
  end

  get "/array/:uuid" do
    {:ok, result} = Redix.command(:redix, ["GET", uuid])

    case result do
      nil ->
        result = Jason.encode!(%{error: "No such uuid"})
        send_resp(conn, 404, result)

      list ->
        list_formated = Jason.decode!(list)
        result = Jason.encode!(%{list: list_formated, uuid: uuid})
        send_resp(conn, 200, result)
    end
  end

  post "/array" do
    list = Map.get(conn.body_params, "list")

    if Util.is_valid_list(list) do
      {:ok, old_list_encoded} = Jason.encode(list)
      uuid = UUID.uuid5(nil, old_list_encoded)
      {:ok, saved_array} = Redix.command(:redix, ["GET", uuid])

      case saved_array do
        nil ->
          new_list = SortList.process_list(list)
          {:ok, list_encoded} = Jason.encode(new_list)

          conn = assign(conn, :list, new_list)
          conn = assign(conn, :uuid, uuid)
          Redix.command!(:redix, ["SET", uuid, list_encoded])
          result = Jason.encode!(%{list: new_list, uuid: uuid})
          send_resp(conn, 200, result)

        saved_array ->
          # Converting from "[1,2,3]" to [1,2,3]
          array_in_list = Jason.decode!(saved_array)

          result = Jason.encode!(%{list: array_in_list, uuid: uuid, cached: true})
          send_resp(conn, 200, result)
      end
    else
      result = Jason.encode!(%{error: "Invalid array"})
      send_resp(conn, 400, result)
    end
  end

  match _ do
    send_resp(conn, 404, "There is no such route")
  end
end
