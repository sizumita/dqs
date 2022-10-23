defmodule Dqs.Command.Search do
  alias Dqs.Repo
  import Ecto.Query
  import Nostrum.Struct.Embed
  @prefix Application.get_env(:dqs, :prefix)
  @guild_id Application.get_env(:dqs, :guild_id)

  def handle(%{content: @prefix <> "find tag " <> tags_text} = msg) do
    tags = tags_text |> String.split(" ") |> MapSet.new() |> MapSet.to_list()
    query = from(
      p in Dqs.Question,
      preload: [:info],
      where: fragment("? @> ?::varchar[]", p.tag, ^tags) and p.status != "erased"
    )
    send_embeds(msg.channel_id, make_embeds(Repo.all(query), tags_text))
  end

  def handle(%{content: @prefix <> "find " <> text} = msg) do
    query = from(
      p in Dqs.Question,
      preload: [:info],
      where: fragment("name &@~ ?", ^text) and p.status != "erased"
    )
    send_embeds(msg.channel_id, make_embeds(Repo.all(query), text))
  end

  def make_embeds(questions, tags_text) do
    links = questions
      |> Enum.map(fn question ->
      ~s/[**#{question.name}**](https:\/\/discord.com\/channels\/#{@guild_id}\/#{question.channel_id}\/#{question.info.original_message_id})\n\n/
    end)

    embeds = Dqs.Embed.make_search_result_embed([], links) |> Enum.reverse()
    case embeds do
      [first | rest] ->
        first_edited = first
                       |> put_title("検索結果")
                       |> put_description(~s/`#{tags_text}`の検索結果(#{Enum.count(questions)}件)を表示します。\n\n/ <> first.description)
        [first_edited | rest]
      [] ->
        [%Nostrum.Struct.Embed{}
          |> put_title("検索結果")
          |> put_color(0xff0000)
          |> put_description("一件も見つかりませんでした。")]
    end
  end

  def send_embeds(channel_id, []), do: :ok

  def send_embeds(channel_id, embeds) do
    [first | rest] = embeds
    case Nostrum.Api.create_message(channel_id, embed: first) do
      {:ok, _} -> send_embeds(channel_id, rest)
      _ ->
        :timer.sleep(1000 * 5)
        send_embeds(channel_id, embeds)
    end
  end
end
