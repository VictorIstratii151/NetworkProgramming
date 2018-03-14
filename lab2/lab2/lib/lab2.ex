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

end