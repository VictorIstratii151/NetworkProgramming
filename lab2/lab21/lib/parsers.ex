defmodule Lab21.Parsers do
  def decode_csv(data) do
    data |> String.split("\n") |> CSV.decode() |> Enum.to_list() |> Keyword.take([:ok])
  end
end
