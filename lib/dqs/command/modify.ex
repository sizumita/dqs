defmodule Dqs.Command.Modify do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache

  @prefix Application.get_env(:dqs, :prefix)
  @board_channel_id Application.get_env(:dqs, :board_channel_id)

  def handle(%{content: @prefix <> "set title " <> title} = msg) do
    set_title(msg, title)
  end

  def handle(%{content: @prefix <> "set content"} = msg) do
    case msg.referenced_message do
      nil -> Nostrum.Api.create_message(msg.channel_id, "リプライ元が存在しません。")
      referenced_message -> set_content(msg, referenced_message.content)
    end
  end

  def handle(%{content: @prefix <> "set content " <> content} = msg) do
    set_content(msg, content)
  end

  def set_title(msg, title) do
    channel_id = msg.channel_id
    question =
      from(
        question in Dqs.Question,
        where: question.channel_id == ^channel_id and question.status == "open",
        preload: [:info],
        select: question
      )
      |> Repo.one()
      |> Ecto.Changeset.change(name: title)
    with false <- Dqs.Ratelimit.ratelimit?(msg.channel_id),
         {:ok, _channel} <- update_channel_name(msg, title),
         {:ok, question} <- do_update(question),
         {:ok, _message} <- update_info_message(question)
      do
      send_message(msg, "変更しました。")
    else
      true -> Dqs.Error.rate_limit(msg)
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
        Dqs.Error.retry_after(msg, retry_after)
        Dqs.Ratelimit.wait_ratelimit(msg.channel_id, retry_after)
      e -> send_message(msg, "アップデートができませんでした。再度お試しください。")
           IO.inspect(e)
    end
  end

  def send_message(msg, content) do
    Nostrum.Api.create_message(msg.channel_id, content)
  end

  def update_channel_name(msg, title) do
    Nostrum.Api.modify_channel(msg.channel_id, name: title)
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

  def set_content(msg, content) do
    channel_id = msg.channel_id
    question =
      from(
        question in Dqs.Question,
        where: question.channel_id == ^channel_id and question.status == "open",
        preload: [:info],
        select: question
      )
      |> Repo.one()
      |> Ecto.Changeset.change(content: content)
    with {:ok, question} <- do_update(question),
         {:ok, _message} <- update_info_message(question)
      do
      send_message(msg, "変更しました。")
    else
      true -> Dqs.Error.rate_limit(msg)
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
        Dqs.Error.retry_after(msg, retry_after)
      _error -> send_message(msg, "アップデートができませんでした。再度お試しください。")
    end
  end

  def do_update(question) do
    case Repo.update question do
      {:ok, question} -> {:ok, question}
      {:error, _} -> {:error, :update}
    end
  end
end
