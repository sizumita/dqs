defmodule Dqs.Command.Create do
  alias Dqs.Repo
  import Nostrum.Struct.Embed

  @prefix Application.get_env(:dqs, :prefix)
  @open_category_id Application.get_env(:dqs, :open_category_id)
  @closed_category_id Application.get_env(:dqs, :closed_category_id)
  @board_channel_id Application.get_env(:dqs, :board_channel_id)

  def handle_message(%{content: name} = msg) do
    {:ok, channels} = Nostrum.Api.get_guild_channels(msg.guild_id)
    closed_channels = channels
                      |> Enum.filter(fn channel -> channel.parent_id == @closed_category_id end)
    try_transaction(msg, closed_channels, name)
  end

  def try_transaction(msg, channels, name) do
    case channels do
      [] -> send_message msg, "空きチャンネルがないか、操作可能なチャンネルがありません。管理者にご連絡ください。"
      [first | rest] ->
        Repo.transaction(
          fn ->
            with {:ok} <- check_duplicate(first),
                 {:ok, _channel} <- edit_channel(name, first),
                 {:ok, question} <- create_question(msg, name, first),
                 {:ok, question_message} <- send_question_message(msg, name, question, first),
                 {:ok, info_message} <- send_info_message(msg, question_message, question),
                 {:ok, _question_info} <- create_question_info(question_message, question, info_message)
              do
              send_notice_message(msg, first)
            else
              {:error, %Nostrum.Error.ApiError{status_code: 429}} -> try_transaction(msg, rest, name)
              {:error, e} -> send_message(msg, "エラーが発生しました。再度お試しください。")
                             IO.inspect e
                             Repo.rollback(e)
            end
          end
        )
    end
  end

  def edit_channel(name, alloc_channel) do
    {:ok, parent_channel} = Dqs.Cache.get_channel(@open_category_id)
    Nostrum.Api.modify_channel(alloc_channel.id, name: name, parent_id: @open_category_id, permission_overwrites: parent_channel.permission_overwrites)
  end

  def check_duplicate(alloc_channel) do
    question = Repo.get_by(Dqs.Question, channel_id: alloc_channel.id, status: "open")
    if question == nil do
      {:ok}
    else
      {:error, :duplicate}
    end
  end

  def send_notice_message(msg, alloc_channel) do
    message = ~s/<@#{msg.author.id}>, 質問を作成しました。\n
`#{@prefix}set content [質問の概要]`と送信するか、質問の概要を送信した後にリプライで`!set content`と入力すると質問内容を保存します。\n
`#{@prefix}set title [タイトル]`でタイトルを変更できます。\n
`!close`で質問を終了させることができます。\n以上の操作が難しい場合、他のユーザーに頼んでください。/
    Nostrum.Api.create_message(alloc_channel.id, message)
  end

  def send_question_message(msg, name, question, alloc_channel) do
    embed = %Nostrum.Struct.Embed{}
            |> put_title("新しい質問: " <> name)
            |> put_author(~s/ID:#{question.id}/, "", "")
            |> put_field("投稿者", ~s/#{msg.author.username}##{msg.author.discriminator} (<@#{msg.author.id}>)/)

    Nostrum.Api.create_message(alloc_channel.id, embed: embed)
  end

  def send_info_message(msg, question_message, question) do
    embed = Dqs.Embed.make_info_embed(
      msg.author,
      question,
      %Dqs.QuestionInfo{
        original_message_id: question_message.id,
        info_message_id: 0,
        question: question
      }
    )
    Nostrum.Api.create_message(@board_channel_id, embed: embed)
  end

  def create_question_info(msg, question, info_message) do
    %Dqs.QuestionInfo{
      original_message_id: msg.id,
      info_message_id: info_message.id,
      question: question
    }
    |> Repo.insert()
  end

  def create_question(msg, name, alloc_channel) do
    Repo.insert(
      %Dqs.Question{
        issuer_id: msg.author.id,
        name: name,
        content: "",
        status: "open",
        channel_id: alloc_channel.id
      }
    )
  end

  def send_message(msg, content) do
    Nostrum.Api.create_message(msg.channel_id, content)
  end
end
