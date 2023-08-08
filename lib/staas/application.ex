defmodule Staas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    uri = Application.get_env(:staas, :uri)
    # Read variable Redis.Url
    # connect to it

    children = [
      {Bandit, plug: Staas.Router, scheme: :http, port: 4000},
      {Redix, {uri, name: :redix, sync_connect: true}}
    ]

    opts = [strategy: :one_for_one, name: Staas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
