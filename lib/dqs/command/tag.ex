defmodule Dqs.Command.Tag do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache
  @prefix System.get_env("PREFIX")
  @board_channel_id System.get_env("QUESTION_BOARD_CHANNEL_ID")
                    |> String.to_integer

  def handle(%{content: @prefix <> "tag add " <> tags} = msg) do
    question = get_current_question(msg.channel_id)
    tags = tags |> String.split(" ") |> MapSet.new()
    old_tags = question.tag |> MapSet.new()
    new_tags = MapSet.union(old_tags, tags)

    with {:ok, question} <- change_tag(question, new_tags),
         {:ok, _message} <- update_info_message(question)
    do
      Nostrum.Api.create_message(msg.channel_id, "タグを追加しました。")
    else
      e -> IO.inspect(e)
           Nostrum.Api.create_message(msg.channel_id, "タグを追加できませんでした。時間を開けて再度お試しください。")
    end
  end

  def handle(%{content: @prefix <> "tag remove " <> tags} = msg) do
    question = get_current_question(msg.channel_id)
    tags = tags |> String.split(" ") |> MapSet.new()
    old_tags = question.tag |> MapSet.new()
    new_tags = MapSet.difference(old_tags, tags)

    with {:ok, new_question} <- change_tag(question, new_tags),
         {:ok, _message} <- update_info_message(new_question)
      do
      Nostrum.Api.create_message(msg.channel_id, "タグを削除しました。")
    else
      e -> IO.inspect(e)
           Nostrum.Api.create_message(msg.channel_id, "タグを追加できませんでした。時間を開けて再度お試しください。")
    end
  end

  def handle(_msg), do: :noop

  def get_current_question(channel_id) do
    from(
      question in Dqs.Question,
      where: question.channel_id == ^channel_id,
      preload: [:info],
      select: question
    )
    |> Repo.one()
  end

  def update_info_message(question) do
    info = question.info
    {:ok, user} = Cache.get_user(question.issuer_id)
    Nostrum.Api.edit_message(
      @board_channel_id,
      info.info_message_id,
      embed: Dqs.Embed.make_info_embed(user, question, question.info)
    )
  end

  def change_tag(question, tags) do
    question |> Ecto.Changeset.change(tag: tags |> MapSet.to_list()) |> Repo.update
  end

end