defmodule Dqs.Command.Close do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache
  @board_channel_id System.get_env("QUESTION_BOARD_CHANNEL_ID")
                    |> String.to_integer
  @closed_category_id System.get_env("CLOSED_CATEGORY_ID")
                      |> String.to_integer

  def handle(msg) do
    question = get_current_question(msg.channel_id)

    with {:ok, question} <- close_question(question),
         {:ok, _message} <- update_info_message(question),
         {:ok, _channel} <- edit_channel(msg.channel_id)
    do
      Nostrum.Api.create_message(msg.channel_id, "closeされました。")
    else
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
          Nostrum.Api.create_message(msg.channel_id, ~s/レートリミットによりcloseできませんでした。約#{retry_after/60}秒後に再度行ってください。/)
      _ -> Nostrum.Api.create_message(msg.channel_id, "なんらかの理由でcloseできませんでした。再度お試しください。")
    end
  end

  def update_info_message(question) do
    info = question.info
    {:ok, user} = Cache.get_user(question.issuer_id)
    Nostrum.Api.edit_message(
      @board_channel_id,
      info.info_message_id,
      embed: Dqs.Embed.make_info_embed(user, question, question.info),
      color: 0xff3333
    )
  end

  def close_question(question) do
    question |> Ecto.Changeset.change(status: "closed") |> Repo.update
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