defmodule Lab2.Parsers do


defmodule Lab2.Parsers do

      defp with_sigil(data, sigil) do
          data
          |> SweetXml.xpath(SweetXml.sigil_x ("/device/" <> sigil))
          |> to_string
      end

      def parse_xml(data) do
          %{
              "device_id" => with_sigil(data, "@id"),
              "sensor_type" => data
                               |> with_sigil("type/text()")
                               |> String.to_integer,
              "value" => data
                         |> with_sigil("value/text()")
                         |> String.to_float
          }
      end

      def parse_json(data) do
          Poison.decode! data
      end

      def parse_csv(data) do
          data
          |> NimbleCSV.RFC4180.parse_string
          |> Enum.map(fn [d_id, s_t, v] -> %{
                            "device_id" => d_id,
                            "sensor_type" => String.to_integer(s_t),
                            "value" => String.to_float(v)
                        } end)
      end

  end
end