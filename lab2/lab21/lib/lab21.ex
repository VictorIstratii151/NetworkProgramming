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
  def fetch_data(:categories) do
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
    - `start_date`: String in the format "YYY-MM-DD" that specifies the start of the time interval
    - `end_date`: String in the format "YYY-MM-DD" that specifies the end of the time interval
  """

  def fetch_data(:orders, start_date, end_date) do
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

  def ords do
    fetch_data(:orders, @test_start, @test_end)
  end

  def cats do
    fetch_data(:categories) |> Lab21.Parsers.decode_csv()
  end

  # remove keywords from keyword list and get rid of the column names
  def clean_structure(data) do
    without_ok = remove_keywords(data)
    {col_names, without_col_names} = List.pop_at(without_ok, 0)
  end

  def remove_keywords(data) do
    Keyword.get_values(data, :ok)
  end

  def separate_categories do
    categories = fetch_data(:categories) |> Lab21.Parsers.decode_csv()

    {roots, rest} =
      Enum.split_with(categories, fn elem ->
        decision =
          case elem do
            {:ok, [_, _, ""]} ->
              true

            {:ok, _} ->
              false
          end
      end)

    roots
  end

  def foo do
    orders = ords() |> Lab21.Parsers.decode_csv()
    {_, clean_orders} = clean_structure(orders)
    clean_orders
  end

  def total_tests() do
    cats = sas()
    ords = foo()

    # ords = [
    #   ["", "1", "1", ""]
    # ]

    categories_with_parents = map_category_parents(cats)

    IO.inspect(categories_with_parents)
    # IO.inspect(ords)
    Enum.map(ords, fn ord ->
      IO.inspect(ord)
    end)

    totals = get_totals_for_all_categories(categories_with_parents, ords, %{})
  end

  def pretty_print_totals(totals_map, categories_with_parents) do
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

  # temporary function for testing the totals for each category separatedly 
  def bar() do
    categories = fetch_data(:categories) |> Lab21.Parsers.decode_csv()
    {ids, categories} = clean_structure(categories)
    orders = foo()

    Enum.map(categories, fn [id, name, parent_id] ->
      {id, get_totals(id, orders, "0")}
    end)
  end

  def baz(category_list) do
    for category <- category_list,
        {id, _, parent_id} <- category,
        do: IO.puts(id)
  end

  def sas do
    cats = cats()
    {ids, cats} = clean_structure(cats)
    cats
  end

  # ["16", "VR/AR", "14"]
  # ["24", "Food & Grocery", ""]
  # ["12", "TV", "11"]
  def test_parent() do
    categories = sas()
    category = ["12", "TV", "11"]

    find_parents(category, categories, [])
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
