defmodule ThousandIsland.Transport do
  @moduledoc """
  This module describes the behaviour required for Thousand Island to interact
  with low-level sockets. It is largely internal to Thousand Island, however users
  are free to implement their own versions of this behaviour backed by whatever
  underlying transport they choose. Such a module can be used in Thousand Island
  by passing its name as the `transport_module` option when starting up a server,
  as described in `ThousandIsland`.
  """

  @typedoc "A listener socket used to wait for connections"
  @type listener_socket() :: any()

  @typedoc "A socket representing a client connection"
  @type socket() :: any()

  @typedoc "Information about an endpoint (either remote ('peer') or local"
  @type socket_info() :: %{
          address: :inet.ip_address() | :inet.local_address(),
          port: :inet.port_number(),
          ssl_cert: String.t() | nil
        }

  @typedoc "Connection statistics for a given socket"
  @type socket_stats() :: {:ok, [{:inet.stat_option(), integer()}]} | {:error, :inet.posix()}

  @typedoc "Options which can be set on a socket via setopts/2 (or returned from getopts/1)"
  @type socket_get_options() :: [:inet.socket_getopt()]

  @typedoc "Options which can be set on a socket via setopts/2 (or returned from getopts/1)"
  @type socket_set_options() :: [:inet.socket_setopt()]

  @typedoc "The direction in which to shutdown a connection in advance of closing it"
  @type way() :: :read | :write | :read_write

  @typedoc "The return value from a getopts/2 call"
  @type on_getopts() :: {:ok, socket_set_options()} | {:error, any()}

  @typedoc "The return value from a setopts/2 call"
  @type on_setopts() :: :ok | {:error, any()}

  @typedoc "The return value from a recv/3 call"
  @type on_recv() :: {:ok, binary()} | {:error, any()}

  @typedoc "The return value from a send/2 call"
  @type on_send() :: :ok | {:error, any()}

  @typedoc "The return value from a sendfile/4 call"
  @type on_sendfile() :: {:ok, non_neg_integer()} | {:error, any()}

  @typedoc "The return value from a handshake/1 call"
  @type on_handshake() :: {:ok, socket()} | {:error, any()}

  @typedoc "The return value from a shutdown/2 call"
  @type on_shutdown() :: :ok

  @typedoc "The return value from a close/1 call"
  @type on_close() :: :ok

  @typedoc "The return value from a negotiated_protocol/1 call"
  @type negotiated_protocol_info() :: {:ok, binary()} | {:error, :protocol_not_negotiated}

  @doc """
  Create and return a listener socket bound to the given port and configured per
  the provided options.
  """
  @callback listen(:inet.port_number(), keyword()) :: {:ok, listener_socket()}

  @doc """
  Wait for a client connection on the given listener socket. This call blocks until
  such a connection arrives, or an error occurs (such as the listener socket being
  closed).
  """
  @callback accept(listener_socket()) :: {:ok, socket()} | {:error, any()}

  @doc """
  Performs an initial handshake on a new client connection (such as that done
  when negotiating an SSL connection). Transports which do not have such a
  handshake can simply pass the socket through unchanged.
  """
  @callback handshake(socket()) :: on_handshake()

  @doc """
  Transfers ownership of the given socket to the given process. This will always
  be called by the process which currently owns the socket.
  """
  @callback controlling_process(socket(), pid()) :: :ok | {:error, any()}

  @doc """
  Returns available bytes on the given socket. Up to `num_bytes` bytes will be
  returned (0 can be passed in to get the next 'available' bytes, typically the
  next packet). If insufficient bytes are available, the function can wait `timeout`
  milliseconds for data to arrive.
  """
  @callback recv(socket(), num_bytes :: non_neg_integer(), timeout :: timeout()) :: on_recv()

  @doc """
  Sends the given data (specified as a binary or an IO list) on the given socket.
  """
  @callback send(socket(), data :: IO.chardata()) :: on_send()

  @doc """
  Sends the contents of the given file based on the provided offset & length
  """
  @callback sendfile(
              socket(),
              filename :: String.t(),
              offset :: non_neg_integer(),
              length :: non_neg_integer()
            ) :: on_sendfile()

  @doc """
  Gets the given options on the socket.
  """
  @callback getopts(socket(), socket_get_options()) :: on_getopts()

  @doc """
  Sets the given options on the socket. Should disallow setting of options which
  are not compatible with Thousand Island
  """
  @callback setopts(socket(), socket_set_options()) :: on_setopts()

  @doc """
  Shuts down the socket in the given direction.
  """
  @callback shutdown(socket(), way()) :: on_shutdown()

  @doc """
  Closes the given socket.
  """
  @callback close(socket() | listener_socket()) :: on_close()

  @doc """
  Returns information in the form of `t:socket_info()` about the local end of the socket.
  """
  @callback local_info(socket() | listener_socket()) :: socket_info()

  @doc """
  Returns information in the form of `t:socket_info()` about the remote end of the socket.
  """
  @callback peer_info(socket()) :: socket_info()

  @doc """
  Returns whether or not this protocol is secure.
  """
  @callback secure?() :: boolean()

  @doc """
  Returns stats about the connection on the socket.
  """
  @callback getstat(socket()) :: socket_stats()

  @doc """
  Returns the protocol negotiated as part of handshaking. Most typically this is via TLS'
  ALPN or NPN extensions. If the underlying transport does not support protocol negotiation
  (or if one was not negotiated), `{:error, :protocol_not_negotiated}` is returned
  """
  @callback negotiated_protocol(socket()) :: negotiated_protocol_info()
end
