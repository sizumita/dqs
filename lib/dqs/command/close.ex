defmodule Dqs.Command.Close do
  alias Dqs.Repo
  import Ecto.Query

  alias Dqs.Cache
  @board_channel_id Application.get_env(:dqs, :board_channel_id)
  @closed_category_id Application.get_env(:dqs, :closed_category_id)

  def delay(channel_id) do
    case Cachex.get(:delay_close, to_string(channel_id)) do
      { :ok, nil } ->
        Nostrum.Api.create_message(channel_id, "1時間後にcloseされます。")
        Cachex.put(:delay_close, to_string(channel_id), true)
        :timer.sleep(1000 * 60 * 60)
        case Cachex.get(:delay_close, to_string(channel_id)) do
          { :ok, nil } -> {:error, :canceled}
          _ ->
            Cachex.del(:delay_close, to_string(channel_id))
            {:ok}
        end
      _ ->
        {:error, :already_closing}
    end
  end

  def handle(msg) do
    question = Dqs.Action.get_current_question(msg.channel_id)

    with {:ok} <- delay(msg.channel_id),
         false <- Dqs.Ratelimit.ratelimit?(msg.channel_id),
         {:ok, _channel} <- edit_channel(msg.channel_id),
         {:ok, question} <- Dqs.Action.close_question(question),
         {:ok, _message} <- Dqs.Action.update_info_message(question)
    do
      Nostrum.Api.create_message(msg.channel_id, "closeされました。")
    else
      true -> Nostrum.Api.create_message(msg.channel_id, "レートリミットによりcloseできませんでした。しばらく経ってから再度お試しください。")
      {:error, %Nostrum.Error.ApiError{status_code: 429, response: %{retry_after: retry_after}}} ->
          Nostrum.Api.create_message(msg.channel_id, ~s/レートリミットによりcloseできませんでした。約#{Float.floor(retry_after/60000)}分後に再度行ってください。/)
          Dqs.Ratelimit.wait_ratelimit(msg.channel_id, retry_after)
      {:error, :canceled} -> :noop
      {:error, :already_closing} -> Nostrum.Api.create_message(msg.channel_id, "すでにcloseが予定されています。")
      _ -> Nostrum.Api.create_message(msg.channel_id, "なんらかの理由でcloseできませんでした。再度お試しください。")
    end
  end

  def update_info_message(question) do
    {:ok, user} = Cache.get_user(question.issuer_id)
    Dqs.Action.update_info_message(
      question,
      Dqs.Embed.make_info_embed(user, question, question.info, 0xff3333)
    )
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
