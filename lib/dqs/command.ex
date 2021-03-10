defmodule Dqs.Command do
  @prefix System.get_env("PREFIX")

  def handle(%{content: @prefix <> "create " <> _name} = msg) do
    Dqs.Command.Create.handle(msg)
  end

  def handle(_msg) do
    :noop
  end

  defp create_message(channel_id, message) do
    Nostrum.Api.create_message(channel_id, message)
  end
end
