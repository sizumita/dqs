defmodule Dqs.Action do
  alias Dqs.Repo
  import Ecto.Query
  alias Dqs.Cache
  @board_channel_id Application.get_env(:dqs, :board_channel_id)

  def get_current_question(channel_id) do
    from(
      question in Dqs.Question,
      where: question.channel_id == ^channel_id and question.status == "open",
      preload: [:info],
      select: question
    )
    |> Repo.one()
  end

  def close_question(question) do
    question |> Ecto.Changeset.change(status: "closed") |> Repo.update
  end

  def update_info_message(question, embed) do
    info = question.info
    {:ok, user} = Cache.get_user(question.issuer_id)
    Nostrum.Api.edit_message(
      @board_channel_id,
      info.info_message_id,
      embed: embed
    )
  end
end
