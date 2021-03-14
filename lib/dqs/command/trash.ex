defmodule Dqs.Command.Trash do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache
  @board_channel_id System.get_env("QUESTION_BOARD_CHANNEL_ID")
                    |> String.to_integer
  @closed_category_id System.get_env("CLOSED_CATEGORY_ID")
                      |> String.to_integer

  def handle(msg) do
    question = get_current_question(msg.channel_id)

    with {:ok, _channel} <- edit_channel(msg.channel_id),
         {:ok, question} <- trash_question(question),
         {:ok} <- delete_info_message(question)
      do
      Nostrum.Api.create_message(msg.channel_id, "closeされました。")
    else
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
        Nostrum.Api.create_message(msg.channel_id, ~s/レートリミットによりcloseできませんでした。約#{Float.floor(retry_after/60000)}分後に再度行ってください。/)
      e -> Nostrum.Api.create_message(msg.channel_id, "なんらかの理由でcloseできませんでした。再度お試しください。")
           IO.inspect(e)
    end
  end

  def delete_info_message(question) do
    Nostrum.Api.delete_message(@board_channel_id, question.info.info_message_id)
  end

  def get_current_question(channel_id) do
    from(
      question in Dqs.Question,
      where: question.channel_id == ^channel_id and question.status == "open",
      preload: [:info],
      select: question
    )
    |> Repo.one()
  end

  def trash_question(question) do
    question |> Ecto.Changeset.change(status: "erased") |> Repo.update
  end

  def edit_channel(channel_id) do
    {:ok, parent_channel} = Dqs.Cache.get_channel(@closed_category_id)
    Nostrum.Api.modify_channel(
      channel_id,
      name: "空きチャンネル",
      parent_id: @closed_category_id,
      permission_overwrites: parent_channel.permission_overwrites
    )

  end
end