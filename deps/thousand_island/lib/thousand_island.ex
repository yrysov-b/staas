defmodule ThousandIsland do
  @moduledoc """
  Thousand Island is a modern, pure Elixir socket server, inspired heavily by
  [ranch](https://github.com/ninenines/ranch). It aims to be easy to understand
  & reason about, while also being at least as stable and performant as alternatives.

  Thousand Island is implemented as a supervision tree which is intended to be hosted
  inside a host application, often as a dependency embedded within a higher-level
  protocol library such as [Bandit](https://github.com/mtrudel/bandit). Aside from
  supervising the Thousand Island process tree, applications interact with Thousand
  Island primarily via the `ThousandIsland.Handler` behaviour.

  ## Handlers

  The `ThousandIsland.Handler` behaviour defines the interface that Thousand Island
  uses to pass `ThousandIsland.Socket`s up to the application level; together they
  form the primary interface that most applications will have with Thousand Island.
  Thousand Island comes with a few simple protocol handlers to serve as examples;
  these can be found in the [examples](https://github.com/mtrudel/thousand_island/tree/main/examples)
  folder of this project. A simple implementation would look like this:

  ```elixir
  defmodule Echo do
    use ThousandIsland.Handler

    @impl ThousandIsland.Handler
    def handle_data(data, socket, state) do
      ThousandIsland.Socket.send(socket, data)
      {:continue, state}
    end
  end

  {:ok, pid} = ThousandIsland.start_link(port: 1234, handler_module: Echo)
  ```

  For more information, please consult the `ThousandIsland.Handler` documentation.

  ## Starting a Thousand Island Server

  A typical use of `ThousandIsland` might look like the following:

  ```elixir
  defmodule MyApp.Supervisor do
    # ... other Supervisor boilerplate

    def init(config) do
      children = [
        # ... other children as dictated by your app
        {ThousandIsland, port: 1234, handler_module: MyApp.ConnectionHandler}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end
  ```

  You can also start servers directly via the `start_link/1` function:

  ```elixir
  {:ok, pid} = ThousandIsland.start_link(port: 1234, handler_module: MyApp.ConnectionHandler)
  ```

  ## Configuration

  A number of options are defined when starting a server. The complete list is
  defined by the `t:ThousandIsland.options/0` type.

  ## Connection Draining & Shutdown

  `ThousandIsland` instances are just a process tree consisting of standard
  Supervisor, GenServer and Task modules, and so the usual rules regarding
  shutdown and shutdown timeouts apply. Immediately upon beginning the shutdown
  sequence the ThousandIsland.ShutdownListener process will cause the listening socket
  to shut down, which in turn will cause all of the `Acceptor` processes to shut
  down as well. At this point all that is left in the supervision tree are several
  layers of Supervisors and whatever `Handler` processes were in progress when
  shutdown was initiated. At this point, standard Supervisor shutdown timeout
  semantics give existing connections a chance to finish things up. `Handler`
  processes trap exit, so they continue running beyond shutdown until they either
  complete or are `:brutal_kill`ed after their shutdown timeout expires.

  ## Logging & Telemetry

  As a low-level library, Thousand Island purposely does not do any inline
  logging of any kind. The `ThousandIsland.Logger` module defines a number of
  functions to aid in tracing connections at various log levels, and such logging
  can be dynamically enabled and disabled against an already running server. This
  logging is backed by telemetry events internally.

  Thousand Island emits a rich set of telemetry events including spans for each
  server, acceptor process, and individual client connection. These telemetry
  events are documented in the `ThousandIsland.Telemetry` module.
  """

  @typedoc """
  Possible options to configure a server. Valid option values are as follows:

  * `handler_module`: The name of the module used to handle connections to this server.
  The module is expected to implement the `ThousandIsland.Handler` behaviour. Required
  * `handler_options`: A term which is passed as the initial state value to
  `c:ThousandIsland.Handler.handle_connection/2` calls. Optional, defaulting to nil.
  * `genserver_options`: A term which is passed as the value to the handler module's
  underlying `GenServer.start_link/3` call. Optional, defaulting to []
  * `port`: The TCP port number to listen on. If not specified this defaults to 4000.
  If a port number of `0` is given, the server will dynamically assign a port number
  which can then be obtained via `local_info/1`
  * `transport_module`: The name of the module which provides basic socket functions.
  Thousand Island provides `ThousandIsland.Transports.TCP` and `ThousandIsland.Transports.SSL`,
  which provide clear and TLS encrypted TCP sockets respectively. If not specified this
  defaults to `ThousandIsland.Transports.TCP`
  * `transport_options`: A keyword list of options to be passed to the transport module's
  `c:ThousandIsland.Transport.listen/2` function. Valid values depend on the transport
  module specified in `transport_module` and can be found in the documentation for the
  `ThousandIsland.Transports.TCP` and `ThousandIsland.Transports.SSL` modules. Any options
  in terms of interfaces to listen to / certificates and keys to use for SSL connections
  will be passed in via this option
  * `num_acceptors`: The number of acceptor processes to run. Defaults to 100
  * `num_connections`: The maximum number of concurrent connections which each acceptor will
  accept before throttling connections. Connections will be throttled by having the acceptor
  process wait `max_connections_retry_wait` milliseconds, up to `max_connections_retry_count`
  times for existing connections to terminate & make room for this new connection. If there is
  still no room for this new connection after this interval, the acceptor will close the client
  connection and emit a `[:thousand_island, :acceptor, :spawn_error]` telemetry event. This number
  is expressed per-acceptor, so the total number of maximum connections for a Thousand Island
  server is `num_acceptors * num_connections`. Defaults to `16_384`
  * `max_connections_retry_wait`: How long to wait during each iteration as described in
  `num_connectors` above, in milliseconds. Defaults to `1000`
  * `max_connections_retry_count`: How many iterations to wait as described in `num_connectors`
  above. Defaults to `5`
  * `read_timeout`: How long to wait for client data before closing the connection, in
  milliseconds. Defaults to 60_000
  * `shutdown_timeout`: How long to wait for existing client connections to complete before
  forcibly shutting those connections down at server shutdown time, in milliseconds. Defaults to
  15_000. May also be `:infinity` or `:brutal_kill` as described in the `Supervisor`
  documentation
  """
  @type options :: [
          handler_module: module(),
          handler_options: term(),
          genserver_options: GenServer.options(),
          port: :inet.port_number(),
          transport_module: module(),
          transport_options: transport_options(),
          num_acceptors: pos_integer(),
          num_connections: non_neg_integer() | :infinity,
          max_connections_retry_count: non_neg_integer(),
          max_connections_retry_wait: timeout(),
          read_timeout: timeout(),
          shutdown_timeout: timeout()
        ]

  @type transport_options() ::
          ThousandIsland.Transports.TCP.options() | ThousandIsland.Transports.SSL.options()

  @doc false
  @spec child_spec(options()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: {__MODULE__, make_ref()},
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent
    }
  end

  @doc """
  Starts a `ThousandIsland` instance with the given options. Returns a pid
  that can be used to further manipulate the server via other functions defined on
  this module in the case of success, or an error tuple describing the reason the
  server was unable to start in the case of failure.
  """
  @spec start_link(options()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    opts
    |> ThousandIsland.ServerConfig.new()
    |> ThousandIsland.Server.start_link()
  end

  @doc """
  Returns information about the address and port that the server is listening on
  """
  @spec listener_info(pid()) :: {:ok, ThousandIsland.Transport.socket_info()}
  def listener_info(pid) do
    {:ok, pid |> ThousandIsland.Server.listener_pid() |> ThousandIsland.Listener.listener_info()}
  end

  @doc """
  Gets a list of active connection processes. This is inherently a bit of a leaky notion in the
  face of concurrency, as there may be connections coming and going during the period that this
  function takes to run. Callers should account for the possibility that new connections may have
  been made since / during this call, and that processes returned by this call may have since
  completed. The order that connection processes are returned in is not specified
  """
  @spec connection_pids(pid()) :: {:ok, [pid()]}
  def connection_pids(pid) do
    {:ok,
     pid
     |> ThousandIsland.Server.acceptor_pool_supervisor_pid()
     |> ThousandIsland.AcceptorPoolSupervisor.acceptor_supervisor_pids()
     |> Enum.map(&ThousandIsland.AcceptorSupervisor.connection_sup_pid/1)
     |> Enum.flat_map(fn pid ->
       pid
       |> DynamicSupervisor.which_children()
       |> Enum.map(fn {_, connection_pid, _, _} -> connection_pid end)
       |> Enum.filter(&Kernel.is_pid/1)
     end)}
  end

  @doc """
  Synchronously stops the given server, waiting up to the given number of milliseconds
  for existing connections to finish up. Immediately upon calling this function,
  the server stops listening for new connections, and then proceeds to wait until
  either all existing connections have completed or the specified timeout has
  elapsed.
  """
  @spec stop(pid(), timeout()) :: :ok
  def stop(pid, connection_wait \\ 15_000) do
    Supervisor.stop(pid, :normal, connection_wait)
  end
end
