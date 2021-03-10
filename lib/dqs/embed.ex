defmodule Dqs.Embed do
  import Nostrum.Struct.Embed
  @guild_id System.get_env("GUILD_ID")
            |> String.to_integer

  def make_info_embed(user, question, info, color \\ 0x12e327) do
    %Nostrum.Struct.Embed{}
    |> put_title(question.name)
    |> put_author(~s/ID:#{question.id}/, "", "")
    |> put_description(if question.content == nil, do: "なし", else: question.content)
    |> put_field("投稿者", ~s/#{user.username}##{user.discriminator} (<@#{user.id}>)/)
    |> put_field(
         "リンク",
         ~s/[最初のメッセージ](https:\/\/discord.com\/channels\/#{@guild_id}\/#{question.channel_id}\/#{
           info.original_message_id
         })/
       )
    |> put_field("タグ", if(question.tag == [], do: "なし", else: question.tag |> Enum.join(", ")))
    |> put_color(color)
  end
end
