defmodule TcpClient do
  require Logger
  use GenServer

  @ip {127, 0, 0, 1}
  @port 8000

  def send_message(pid, message) do
    GenServer.cast(pid, {:message, message})
  end

  def start do
    GenServer.start(__MODULE__, %{socket: nil})
  end

  def init(state) do
    send(self(), :connect)
    {:ok, state}
  end
end
