defmodule TcpClient do
  require Logger
  use GenServer

  @ip {127, 0, 0, 1}
  @port 8000
end
