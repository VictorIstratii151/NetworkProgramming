defmodule TcpServer do
  require Logger
  use GenServer

  @port 8000

  def start do
    GenServer.start(__MODULE__, %{socket: nil})
  end

  def init(state) do
    {:ok, socket} = :gen_tcp.listen(@port, [:binary, active: true])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{@port}...")
    {:ok, %{state | socket: socket}}
  end
end
