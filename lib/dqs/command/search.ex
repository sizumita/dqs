defmodule Dqs.Command.Search do
  alias Dqs.Repo
  import Ecto.Query
  import Nostrum.Struct.Embed
  @prefix System.get_env("PREFIX")
  @guild_id System.get_env("GUILD_ID")

  def handle(%{content: @prefix <> "find tag " <> tags_text} = msg) do
    tags = tags_text |> String.split(" ") |> MapSet.new() |> MapSet.to_list()
    query = from(
      p in Dqs.Question,
      preload: [:info],
      where: fragment("? @> ?::varchar[]", p.tag, ^tags)
    )
    Nostrum.Api.create_message(msg.channel_id, embed: make_embed(Repo.all(query), tags_text))
  end

  def make_embed(questions, tags_text) do
    text = questions
      |> Enum.reduce("",
           fn (question, acc) ->
             acc <>
             ~s/[**#{question.name}**](https:\/\/discord.com\/channels\/#{@guild_id}\/#{question.channel_id}\/#{question.info.original_message_id})\n/
           end
         )
    %Nostrum.Struct.Embed{}
      |> put_title("検索結果")
      |> put_color(0x00bfff)
      |> put_description(~s/`#{tags_text}`の検索結果(#{Enum.count(questions)}件)を表示します。\n\n/ <> text)
  end
end
