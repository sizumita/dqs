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
    |> put_field("タグ", ~s/`#{question.tag |> Enum.join("`, `")}`/)
    |> put_color(color)
  end

  def make_search_result_embed(texts, []) do
    texts |>
      Enum.map(
        fn text ->
          %Nostrum.Struct.Embed{}
          |> put_description(text)
          |> put_color(0x00bfff)
        end
      )
  end

  def make_search_result_embed(texts, links) do
    case texts do
      [] ->
        [first | rest] = links
        make_search_result_embed([first], rest)
      [first | rest] ->
        if String.length(first) > 1500 do
          make_search_result_embed([hd(links) | [first | rest]], tl(links))
        else
          make_search_result_embed([(first <> hd(links)) | rest], tl(links))
        end
    end
  end
end
