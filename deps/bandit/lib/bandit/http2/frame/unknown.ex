defmodule Bandit.HTTP2.Frame.Unknown do
  @moduledoc false

  alias Bandit.HTTP2.{Frame, Stream}

  defstruct type: nil,
            flags: nil,
            stream_id: nil,
            payload: nil

  @typedoc "An HTTP/2 frame of unknown type"
  @type t :: %__MODULE__{
          type: Frame.frame_type(),
          flags: Frame.flags(),
          stream_id: Stream.stream_id(),
          payload: iodata()
        }

  # Note this is arity 4
  @spec deserialize(Frame.frame_type(), Frame.flags(), Stream.stream_id(), iodata()) :: {:ok, t()}
  def deserialize(type, flags, stream_id, payload) do
    {:ok, %__MODULE__{type: type, flags: flags, stream_id: stream_id, payload: payload}}
  end
end
