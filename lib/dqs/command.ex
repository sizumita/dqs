defmodule Dqs.Command do
  alias Dqs.Cache
  @prefix System.get_env("PREFIX")
  @open_category_id System.get_env("OPEN_CATEGORY_ID")
                    |> String.to_integer

  def handle(%{content: @prefix <> "create " <> _name} = msg) do
    Dqs.Command.Create.handle(msg)
  end

  def handle(%{content: @prefix <> "set " <> _} = msg) do
    {:ok, channel} = Cache.get_channel(msg.channel_id)
    if channel.parent_id == @open_category_id do
      Dqs.Command.Modify.handle(msg)
    else
      create_message(msg.channel_id, "このチャンネルでは使用できません。")
    end
  end

  def handle(%{content: @prefix <> "tag " <> _} = msg) do
    {:ok, channel} = Cache.get_channel(msg.channel_id)
    if channel.parent_id == @open_category_id do
      Dqs.Command.Tag.handle(msg)
    else
      create_message(msg.channel_id, "このチャンネルでは使用できません。")
    end
  end

  def handle(_msg) do
    :noop
  end

  defp create_message(channel_id, message) do
    Nostrum.Api.create_message(channel_id, message)
  end
end
