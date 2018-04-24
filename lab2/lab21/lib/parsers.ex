defmodule Lab21.Parsers do
  def parse_csv_string(data) do
    data |> String.split("\n") |> CSV.decode() |> Enum.to_list() |> Keyword.take([:ok])
  end

  def read_csv_file(filename) do
    File.stream!(filename) |> CSV.decode() |> Enum.to_list() |> Keyword.get_values(:ok)
  end

  def encode_csv(table_data) do
    file = File.open!("serialized_totals.csv", [:write, :utf8])
    table_data |> CSV.encode() |> Enum.each(&IO.write(file, &1))
  end
end
