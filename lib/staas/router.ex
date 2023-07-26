defmodule Staas.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/:list" do
    res = Redix.command(:redix, ["GET", list])

    case res do
      {:ok, nil} ->
        send_resp(conn, 200, "nil")

      {:ok, value} ->
        send_resp(conn, 200, value)

      _ ->
        send_resp(conn, 404, "Something wrong with redis server")
    end
  end

  post "/:list" do
    result =
      list
      |> Staas.Modifiers.to_list()
      # TO DO real sort
      |> Enum.sort()
      |> Staas.Modifiers.to_string()

    res = Redix.command(:redix, ["SET", list, result])

    case res do
      {:ok, _} ->
        send_resp(conn, 201, result)

      _ ->
        send_resp(conn, 404, "Something wrong with redis server")
    end
  end

  match _ do
    send_resp(conn, 404, "There is no route")
  end
end
