defmodule Server do
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

  def parse(line) do
    case String.split(line) do
      ["/help"] -> {:ok, print_help()}
      ["/hello" | tail] -> {:ok, tail}
      ["/time"] -> {:ok, get_current_time()}
      ["/random", start_bound, end_bound] -> {:ok, generate_random(start_bound, end_bound)}
      ["/coinflip"] -> {:ok, coin_flip()}
      _ -> {:error, :unknown_command}
    end
  end

  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)

    Logger.info("Client connected")
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Received #{data}")
    Logger.info("Sending it back")

    :ok = :gen_tcp.send(socket, data)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}
end
