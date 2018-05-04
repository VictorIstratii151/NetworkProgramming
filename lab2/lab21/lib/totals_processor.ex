require Logger

defmodule Lab21.TotalsProcessor do
  def listen do
    receive do
      {from, start_date, end_date} ->
        IO.puts("Got message from #{inspect(from)}")
        perform_computations(from, start_date, end_date)
    end

    listen()
  end

  @doc """
  Worker function which processes all the data concurrently, caches it and prints it

  #Parameters
    - `from`: the PID of the caller process
    - `start_date`: String in the format "YYYY-MM-DD" that specifies the start of the time interval
    - `end_date`: String in the format "YYYY-MM-DD" that specifies the end of the time interval
  """

  def perform_computations(from, start_date, end_date) do
    Logger.info("Fetching categories, please wait.")
    fetching_categories = Task.async(fn -> Lab21.clean_categories() end)
    Logger.info("Fetching orders, please wait.")
    fetching_orders = Task.async(fn -> Lab21.clean_orders(start_date, end_date) end)

    categories = Task.await(fetching_categories, 30000)
    Logger.info("Categories fetched")

    orders = Task.await(fetching_orders, 30000)
    Logger.info("Orders fetched")

    categories_with_parents = Lab21.map_category_parents(categories)
    totals = Lab21.get_totals_for_all_categories(categories_with_parents, orders, %{})

    buffered_categories =
      categories_with_parents |> Lab21.indent_categories([]) |> Lab21.add_categories_to_buffer([])

    IO.puts("Printing totals")

    Lab21.print_totals_from_buffer(categories, buffered_categories, totals)
    |> Lab21.cache_totals()
  end
end
