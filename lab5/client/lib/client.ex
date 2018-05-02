defmodule TcpClient do
  require Logger
  use GenServer

  @ip {127, 0, 0, 1}
  @port 8000

  def send_message(pid, message) do
    GenServer.cast(pid, {:message, message})
  end
end
