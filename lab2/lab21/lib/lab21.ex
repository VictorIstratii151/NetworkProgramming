defmodule Lab21 do
  @orders_url Application.fetch_env!(:lab21, :orders_url)
  @categories_url Application.fetch_env!(:lab21, :categories_url)
  @secret_key Application.fetch_env!(:lab21, :secret_key)

  def fetch_data(:categories) do
    case HTTPoison.request(
           :get,
           @categories_url,
           "",
           [{"Accept", "text/csv"}, {"X-API-Key", @secret_key}],
           timeout: 30000,
           recv_timeout: 30000
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts(body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  def fetch_data(:orders, start_date, end_date) do
    case HTTPoison.request(
           :get,
           @orders_url <> "?start=" <> start_date <> "&end=" <> end_date,
           "",
           [{"Accept", "text/csv"}, {"X-API-Key", @secret_key}],
           timeout: 30000,
           recv_timeout: 30000
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts(body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end
end
