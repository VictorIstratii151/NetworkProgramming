defmodule Lab21 do
  @moduledoc """
  This module contains function to fetch, process and store csv data from Evil Legacy API
  """
  @orders_url Application.fetch_env!(:lab21, :orders_url)
  @categories_url Application.fetch_env!(:lab21, :categories_url)
  @secret_key Application.fetch_env!(:lab21, :secret_key)

  @test_start "2018-04-10"
  @test_end "2018-04-12"

  @doc """
  Function that fetches the categories via HTTP

  ##Parameters
    - `:categories`: Atom that specifies that categories should be fetched
  """
  def fetch_data() do
    categories =
      case HTTPoison.request(
             :get,
             @categories_url,
             "",
             [{"Accept", "text/csv"}, {"X-API-Key", @secret_key}],
             timeout: 30000,
             recv_timeout: 30000
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          body

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end

    categories
  end

  @doc """
  Function that fetches the orders via HTTP for a given time interval

  ##Parameters
    - `:orders`: Atom specifying that orders should be fetched
    - `start_date`: String in the format "YYYY-MM-DD" that specifies the start of the time interval
    - `end_date`: String in the format "YYYY-MM-DD" that specifies the end of the time interval
  """

  def fetch_data(start_date, end_date) do
    orders =
      case HTTPoison.request(
             :get,
             @orders_url <> "?start=" <> start_date <> "&end=" <> end_date,
             "",
             [{"Accept", "text/csv"}, {"X-API-Key", @secret_key}],
             timeout: 30000,
             recv_timeout: 30000
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          # IO.puts(body)
          body

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
      end

    orders
  end

  @doc """
  Function for fetching
  """

  def ords(start_date, end_date) do
    fetch_data(@test_start, @test_end) |> Lab21.Parsers.parse_csv_string()
  end

  def cats do
    fetch_data() |> Lab21.Parsers.parse_csv_string()
  end

  # remove keywords from keyword list and get rid of the column names
  def clean_structure(data) do
    without_ok = remove_keywords(data)
    {col_names, without_col_names} = List.pop_at(without_ok, 0)
  end

  def remove_keywords(data) do
    Keyword.get_values(data, :ok)
  end

  def separate_categories(categories) do
    {roots, rest} =
      Enum.split_with(categories, fn elem ->
        decision =
          case elem do
            [_, _, ""] ->
              true

            _ ->
              false
          end
      end)
  end

  def clean_orders(start_date, end_date) do
    orders = ords(start_date, end_date)
    {_, clean_orders} = clean_structure(orders)
    clean_orders
  end

  def clean_categories do
    cats = cats()
    {ids, cats} = clean_structure(cats)
    cats
  end

  ########################################################

  def start_program do
    read_totals_from_file()

    IO.puts("""
    Choose an option:
    1 - Fetch totals for a given time interval
    2 - Exit program
    """)

    ans = IO.getn("Which? > ", 1)

    case ans do
      "1" ->
        mda = IO.getn("")
        start_date = IO.gets("Enter the start of interval (YYYY-MM-DD): ") |> String.trim("\n")

        end_date = IO.gets("Enter the end of interval (YYYY-MM-DD): ") |> String.trim("\n")

        start_computations(start_date, end_date)

      "2" ->
        System.stop(0)
    end
  end

  def start_computations(start_date, end_date) do
    pid = spawn_link(Lab21.TotalsProcessor, :listen, [])
    send(pid, {self(), start_date, end_date})
  end

  def print_totals_from_buffer(categories, buffer_list, totals_map) do
    data_for_serialization =
      for tuple <- buffer_list do
        {id, _, indent_index} = tuple

        [_, matched_category_name, _] =
          Enum.find(categories, fn [category_id, _, _] ->
            id == category_id
          end)

        matched_category_totals = totals_map[id]

        get_totals_row(matched_category_name, matched_category_totals, indent_index)
      end

    Enum.map(data_for_serialization, &IO.puts(&1))

    data_for_serialization
  end

  def get_totals_row(category_name, category_totals, indent_index) do
    {float_totals, _} = Float.parse(category_totals)

    String.pad_trailing(String.duplicate(" ", indent_index * 3) <> "*#{category_name}", 25, "_") <>
      String.pad_leading("#{Float.round(float_totals, 2)}", 10, "_")
  end

  def add_categories_to_buffer(indented_categories, buffer_list)

  def add_categories_to_buffer([], buffer_list) do
    Enum.reverse(buffer_list)
  end

  def add_categories_to_buffer([{id, "", 0} | tail], buffer_list) do
    add_categories_to_buffer(tail, buffer_list ++ [{id, "", 0}])
  end

  def add_categories_to_buffer([head | tail], buffer_list) do
    {id, print_after_id, indent_index} = head

    case Enum.any?(buffer_list, fn {cat_id, _, _} ->
           print_after_id == cat_id
         end) do
      true ->
        append_position =
          Enum.find_index(buffer_list, fn {cat_id, _, _} ->
            print_after_id == cat_id
          end)

        add_categories_to_buffer(tail, List.insert_at(buffer_list, append_position, head))

      false ->
        add_categories_to_buffer(tail ++ [head], buffer_list)
    end
  end

  def indent_categories(categories_with_parents, list_of_tuples)

  def indent_categories([], list_of_tuples) do
    list_of_tuples
  end

  def indent_categories([{category_id, parents_list} | tail], list_of_tuples) do
    cond do
      Enum.count(parents_list) == 0 ->
        indent_categories(tail, [{category_id, "", 0} | list_of_tuples])

      true ->
        indent_categories(tail, [
          {category_id, List.last(parents_list), Enum.count(parents_list)} | list_of_tuples
        ])
    end
  end

  ############################
  ############################

  def test_serialization(totals_string_list) do
    cache_totals(totals_string_list)
    read_totals_from_file()
  end

  def cache_totals(totals_string_list) do
    file = File.open!("serialized_totals.csv", [:write, :utf8])
    totals_string_list |> Enum.each(&IO.write(file, &1 <> "\n"))
  end

  def read_totals_from_file() do
    {:ok, string} = File.read("serialized_totals.csv")
    listed_totals = string |> String.split("\n")

    cond do
      Enum.count(listed_totals) > 1 ->
        IO.puts("\nThe totals from last session:\n")
        Enum.map(listed_totals, &IO.puts(&1))

      true ->
        IO.puts("\nNo data recently cached.\n")
    end

    :ok
  end

  def get_totals_for_all_categories(categories_with_parents, order_list, totals_map)

  def get_totals_for_all_categories([], order_list, totals_map) do
    totals_map
  end

  def get_totals_for_all_categories([head | tail], order_list, totals_map) do
    # IO.inspect(head)

    get_totals_for_all_categories(
      tail,
      order_list,
      get_totals_including_parents(head, order_list, totals_map)
    )
  end

  ######################################
  def get_totals_including_parents({category_id, []}, order_list, totals_map) do
    cond do
      Map.has_key?(totals_map, category_id) ->
        {a, _} = Float.parse(totals_map[category_id])
        {b, _} = Float.parse(get_totals(category_id, order_list))

        Map.replace!(
          totals_map,
          category_id,
          Float.to_string(a + b)
        )

      true ->
        Map.put(totals_map, category_id, get_totals(category_id, order_list))
    end
  end

  def get_totals_including_parents({category_id, parent_id_list}, order_list, totals_map) do
    totals_for_parents =
      Enum.map(parent_id_list, fn parent_id ->
        case Map.has_key?(totals_map, parent_id) do
          true ->
            {a, _} = Float.parse(totals_map[parent_id])
            {b, _} = Float.parse(get_totals(category_id, order_list))

            Float.to_string(a + b)

          _ ->
            get_totals(category_id, order_list)
        end
      end)

    category_id_value =
      case Map.has_key?(totals_map, category_id) do
        true ->
          {a, _} = Float.parse(totals_map[category_id])
          {b, _} = Float.parse(get_totals(category_id, order_list))

          Float.to_string(a + b)

        _ ->
          get_totals(category_id, order_list)
      end

    append_list_to_map(
      [category_id | parent_id_list],
      [category_id_value | totals_for_parents],
      totals_map
    )
  end

  def append_list_to_map([], [], map) do
    map
  end

  def append_list_to_map(key_list, value_list, map) do
    [keys_head | keys_tail] = key_list
    [values_head | values_tail] = value_list

    append_list_to_map(keys_tail, values_tail, Map.put(map, keys_head, values_head))
  end

  @doc """
  Function that computes the totals for only one category and returns them as a string

  ##Parameters
   - `category_id`: String containing the category id
   - `order_list`: List of orders, each order being a list in format `[id, total, category_id, date]`
   - `initial_result': String that is usually "0"
  """
  def get_totals(category_id, order_list, initial_result \\ "0")

  def get_totals(_, order_list, result) when Kernel.length(order_list) < 1 do
    result
  end

  def get_totals(category_id, order_list, result) when Kernel.length(order_list) > 0 do
    {order, new_order_list} = List.pop_at(order_list, 0)
    [_, total, cat_id, _] = order

    new_result =
      cond do
        cat_id == category_id ->
          {a, _} = Float.parse(result)
          {b, _} = Float.parse(total)
          Float.to_string(a + b)

        true ->
          result
      end

    get_totals(category_id, new_order_list, new_result)
  end

  def map_category_parents(categories) do
    Enum.map(categories, fn category ->
      # can be changed any time
      [id, _, _] = category
      {id, find_parents(category, categories, [])}
    end)
  end

  def find_parents([_, _, ""], categories, parents_list) do
    parents_list
  end

  def find_parents(category, categories, parents_list) do
    matched_category =
      Enum.find(categories, fn x ->
        [current_id, _, _] = x
        [_, _, cmp_parent_id] = category
        current_id == cmp_parent_id
      end)

    result =
      case matched_category do
        [new_id, _, ""] ->
          find_parents(matched_category, categories, Enum.uniq([new_id | parents_list]))

        [new_id, _, new_parent] ->
          find_parents(
            matched_category,
            categories,
            Enum.uniq([new_id | [new_parent | parents_list]])
          )
      end
  end
end
