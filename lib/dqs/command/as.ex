defmodule Dqs.Command.As do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache

  @prefix Application.get_env(:dqs, :prefix)
  @board_channel_id Application.get_env(:dqs, :board_channel_id)

  def handle(%{content: @prefix <> "as " <> _} = msg) do
    if Regex.match?(~r/#{@prefix}as (?<id>[0-9]+) (?<command>.+)/, msg.content) do
      groups = Regex.named_captures(~r/#{@prefix}as (?<id>[0-9]+) (?<command>.+)/, msg.content)
      question_id = String.to_integer(groups["id"])
      question =
        from(
          question in Dqs.Question,
          where: question.id == ^question_id,
          preload: [:info],
          select: question
        )
        |> Repo.one()
      case question.status do
        "closed" -> do_as(msg, question, groups["command"])
        "open" -> Nostrum.Api.create_message(msg, "開かれている質問に対しては使えません。")
        "erased" -> Nostrum.Api.create_message(msg, "消去されている質問に対しては使えません。")
      end
    end
  end

  def do_as(msg, question, "set content " <> content) do
    set_content(msg, question, content)
  end

  def do_as(msg, question, "set content") do
    case msg.referenced_message do
      nil -> Nostrum.Api.create_message(msg.channel_id, "リプライ元が存在しません。")
      referenced_message -> set_content(msg, question, referenced_message.content)
    end
  end

  def do_as(msg, question, "set title " <> title) do
    question = question |> Ecto.Changeset.change(name: title)
    with {:ok, question} <- do_update(question),
         {:ok, _message} <- update_info_message(question)
    do
      Nostrum.Api.create_message(msg, "変更しました。")
    else
      true -> Dqs.Error.rate_limit(msg)
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
        Dqs.Error.retry_after(msg, retry_after)
      _error -> Nostrum.Api.create_message(msg, "アップデートができませんでした。再度お試しください。")
    end
  end

  def do_as(msg, question, "trash") do
    with {:ok, question} <- trash_question(question),
         {:ok} <- delete_info_message(question)
    do
      Nostrum.Api.create_message(msg, "trashされました。")
    else
      e -> Nostrum.Api.create_message(msg, "なんらかの理由でcloseできませんでした。再度お試しください。")
           IO.inspect(e)
    end
  end

  def do_as(msg, question, "tag remove " <> tags) do
    tags = tags |> String.split(" ") |> MapSet.new()
    old_tags = question.tag |> MapSet.new()
    new_tags = MapSet.difference(old_tags, tags)

    with {:ok, new_question} <- Dqs.Command.Tag.change_tag(question, new_tags),
         {:ok, _message} <- update_info_message(new_question)
      do
      Nostrum.Api.create_message(msg.channel_id, "タグを削除しました。")
    else
      e -> IO.inspect(e)
           Nostrum.Api.create_message(msg.channel_id, "タグを削除できませんでした。時間を開けて再度お試しください。")
    end
  end

  def do_as(msg, question, "tag add " <> tags) do
    tags = tags |> String.split(" ") |> MapSet.new()
    old_tags = question.tag |> MapSet.new()
    new_tags = MapSet.union(old_tags, tags)

    with {:ok, new_question} <- Dqs.Command.Tag.change_tag(question, new_tags),
         {:ok, _message} <- update_info_message(new_question)
      do
      Nostrum.Api.create_message(msg.channel_id, "タグを追加しました。")
    else
      e -> IO.inspect(e)
           Nostrum.Api.create_message(msg.channel_id, "タグを追加できませんでした。時間を開けて再度お試しください。")
    end
  end

  defp delete_info_message(question) do
    Nostrum.Api.delete_message(@board_channel_id, question.info.info_message_id)
  end

  defp trash_question(question) do
    question |> Ecto.Changeset.change(status: "erased") |> Repo.update
  end

  defp set_content(msg, question, content) do
    question = question |> Ecto.Changeset.change(content: content)
    with {:ok, question} <- do_update(question),
         {:ok, _message} <- update_info_message(question)
      do
      Nostrum.Api.create_message(msg, "変更しました。")
    else
      true -> Dqs.Error.rate_limit(msg)
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
        Dqs.Error.retry_after(msg, retry_after)
      _error -> Nostrum.Api.create_message(msg, "アップデートができませんでした。再度お試しください。")
    end
  end

  defp do_update(question) do
    case Repo.update question do
      {:ok, question} -> {:ok, question}
      {:error, _} -> {:error, :update}
    end
  end

  defp update_info_message(question) do
    info = question.info
    {:ok, user} = Cache.get_user(question.issuer_id)
    Nostrum.Api.edit_message(
      @board_channel_id,
      info.info_message_id,
      embed: Dqs.Embed.make_info_embed(user, question, question.info)
    )
  end
end
