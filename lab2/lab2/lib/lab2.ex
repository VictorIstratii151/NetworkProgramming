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

 

end