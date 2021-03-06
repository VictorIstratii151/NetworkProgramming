defmodule Client do
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

  def user_input() do
    IO.gets("\nEnter a command (starts with\"/\")\n") |> String.trim()
  end

  def user_interaction() do
    {:ok, pid} = start()

    message = user_input()
    send_message(pid, message)

    user_interaction(pid)
  end

  def user_interaction(pid) do
    message = user_input()
    send_message(pid, message)

    user_interaction(pid)
  end

  def handle_info(:connect, state) do
    Logger.info("Connecting to #{:inet.ntoa(@ip)}:#{@port}")

    case :gen_tcp.connect(@ip, @port, [:binary, active: true]) do
      {:ok, socket} ->
        {:noreply, %{state | socket: socket}}

      {:error, reason} ->
        disconnect(state, reason)
    end
  end

  def handle_info({:tcp, _, data}, state) do
    Logger.info("Received #{data}")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    IO.puts("closed")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _}, state) do
    IO.puts("error")
    {:stop, :normal, state}
  end

  def handle_cast({:message, message}, %{socket: socket} = state) do
    Logger.info("Sending #{message}")

    :ok = :gen_tcp.send(socket, message)
    {:noreply, state}
  end

  def disconnect(state, reason) do
    Logger.info("Disconnected: #{reason}")
    {:stop, :normal, state}
  end
end
