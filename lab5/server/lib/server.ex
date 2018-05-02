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

  def help_message() do
    """
      Available commands:
      * /hello 'string' -- returns the message after greeting
      * /time -- returns the current time
      * /random 'n1' 'n2' -- returns a random number between n1 and n2
      * /coinflip -- reuturns 0 or 1
    """
  end

  def time() do
    DateTime.utc_now() |> to_string
  end

  def coin_flip() do
    Enum.random(0..1)
  end

  def parse(line) do
    case String.split(line) do
      ["/help"] ->
        {:ok, help_message()}

      ["/hello" | tail] ->
        {:ok, Enum.join(tail, " ")}

      ["/time"] ->
        {:ok, get_current_time()}

      ["/random", start_bound, end_bound] ->
        {:ok, generate_random(Integer.parse(start_bound), Integer.parse(end_bound))}

      ["/coinflip"] ->
        {:ok, coin_flip()}

      _ ->
        {:error, :unknown_command}
    end
  end

  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)

    Logger.info("Client connected")
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Received #{data}")
    Logger.info("Parsing...")

    data =
      case parse(data) do
        {:ok, processed_data} ->
          processed_data

        _ ->
          "UNKNOWN COMMAND"
      end

    :ok = :gen_tcp.send(socket, data)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}
end
