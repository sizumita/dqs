defmodule Dqs.Error do
  def rate_limit(msg) do
    Nostrum.Api.create_message(msg.channel_id, "レートリミットによりアップデートできませんでした。しばらく経ってから再度お試しください。")
  end

  def retry_after(msg, retry_after) do
    Nostrum.Api.create_message(msg.channel_id, ~s/レートリミットによりアップデートできませんでした。約#{Float.floor(retry_after/60000)}分後に再度行ってください。/)
  end
end