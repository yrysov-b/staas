defmodule Staas.Router do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome to StaS")
  end

  get "/:list" do
    result = Staas.Sort.sort(list)
    send_resp(conn, 200, "List is #{result}")
  end

  match _ do
    send_resp(conn, 404, "There is no route")
  end

end
