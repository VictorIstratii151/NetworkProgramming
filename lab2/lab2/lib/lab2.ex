defmodule LAB2 do
  @moduledoc """
  Documentation for Lab2.
  Those awful timeouts...
  """

  @service_root "https://desolate-ravine-43301.herokuapp.com"

  defp get_urls_and_key do
    resp = HTTPotion.post(@service_root)

    {Poison.decode!(resp.body), resp.headers["session"]}
  end

  defp get_body_and_conttype(resp) do
      {resp.headers.hdrs["content-type"], resp.body}
  end

  defp parse({cont_t, content}) do
    case cont_t do
      "text/csv" -> Lab2.Parsers.parse_csv content
      "Application/json" -> Lab2.Parsers.parse_json content
      "Application/xml" -> Lab2.Parsers.parse_xml content
      "text/plain; charset=utf-8" -> IO.puts content
    end
  end

  defp pretty_print(row) do
    sensor_type = case row["sensor_type"] do
        0 -> "Temperature sensor"
        1 -> "Humidity sensor"
        2 -> "Motion sensor"
        3 -> "Alien Presence detector"
        4 -> "Dark Matter detector"
        5 -> "Midichlorian analyzer"
        _ -> "Do we even have it?"
    end
    [
    "[" <> sensor_type <> "]" <> "\n",
    :white, :bright,
    "Device ID: "  <> row["device_id"]
    <> " with value " <> Float.to_string(row["value"])
    <> "\n"] |> IO.ANSI.format |> IO.puts
  end

  def fetch do
      {urls, key} = get_urls_and_key()

      urls
      |> Enum.map(fn url ->
              Task.async(fn ->
                  HTTPotion.get "#{@service_root}#{url["path"]}",
                                [headers: ["session": key],
                                 timeout: 50_000]
              end)
          end)
      |> Enum.map(&Task.await(&1, 50_000))
      |> Enum.map(&get_body_and_conttype(&1))
      |> Enum.map(&parse(&1))
      |> List.flatten
      |> Enum.filter(fn x -> x != :ok end)
      |> Enum.sort(fn x, y -> x["sensor_type"] < y["sensor_type"] end)
      |> Enum.each(&pretty_print(&1))
  end

end