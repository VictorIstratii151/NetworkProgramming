defmodule Lab21 do
  @orders_url Application.fetch_env!(:lab21, :orders_url)
  @categories_url Application.fetch_env!(:lab21, :categories_url)
  @secret_key Application.fetch_env!(:lab21, :secret_key)

  @test_start "2018-04-10"
  @test_end "2018-04-12"

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

  # def remove_col_names do
  #   categories = fetch_data(:categories) |> Lab21.Parsers.decode_csv()
  #   {col_names, without_col_names} = Keyword.pop_first(categories, :ok)
  #   without_ok = Keyword.get_values(without_col_names, :ok)
  # end

  # remove keywords from keyword list and get rid of the column names
  def clean_structure(data) do
    {col_names, without_col_names} = Keyword.pop_first(data, :ok)
    {col_names, Keyword.get_values(without_col_names, :ok)}
  end

  # def compute_totals(categories, totals_map) do
  #   {cat, new_categories} = List.pop_at(categories, 0)
  #   process_totals(cat, totals_map, categories)
  #   compute_totals(new_categories, totals_map)
  # end

  # def process_totals(cat, totals_map, categories) do
  #   {id, name, parent_id} = cat

  #   case parent_id do
  #     "" ->
  #       if Map.has_key?(totals_map, id) do
  #         Map.put(totals_map, id, totals_map[id] + get_totals(id))
  #       else
  #         Map.put_new(totals_map, )
  #       end
  #   end
  # end

  def foo do
    orders = ords() |> Lab21.Parsers.decode_csv()
    {_, clean_orders} = clean_structure(orders)
    clean_orders
  end

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

  def separate_categories do
    categories = fetch_data(:categories) |> Lab21.Parsers.decode_csv()

    Enum.split_with(categories, fn elem ->
      decision =
        case elem do
          {:ok, [_, _, ""]} ->
            true

          {:ok, _} ->
            false
        end

      decision
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
