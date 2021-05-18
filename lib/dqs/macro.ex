defmodule Dqs.Macro do
  alias Dqs.Cache

  defmacro limited_command(msg_r, do: block) do
    quote do
      msg = unquote(msg_r)
      {:ok, channel} = Cache.get_channel(msg.channel_id)
      if channel.parent_id == @open_category_id do
        unquote(block)
      else
        Nostrum.Api.create_message(msg.channel_id, "このチャンネルでは使用できません。")
      end
    end
  end
end
