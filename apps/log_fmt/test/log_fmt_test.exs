defmodule LogFmtTest do
  use ExUnit.Case
  doctest LogFmt

  @timestamp {{2023, 01, 01}, {12, 00, 00, 00}}
  @message ["Log event ", "occurred"]
  @metadata Keyword.new(%{
              healthcheck: %{
                "event" => "finished",
                "name" => "memory",
                "status" => "passing"
              }
            })

  describe "format/4" do
    test "event log level as severity" do
      json_encoded_event = LogFmt.format(:info, @message, @timestamp, @metadata)
      event = Jason.decode!(json_encoded_event)
      assert event["message"] == "Log event occurred"
      assert event["level"] == "info"
      assert event["@severity"] == "info"
    end
  end
end
