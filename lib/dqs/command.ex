defmodule Dqs.Command do
  def on_message(msg) do
    IO.inspect msg
    Nostrum.Api.create_message(msg.channel_id, "pong")
  end
end
