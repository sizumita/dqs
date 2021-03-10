defmodule Dqs.Command.Create do
  alias Dqs.Repo
  import Nostrum.Struct.Embed

  @prefix System.get_env("PREFIX")
  @guild_id System.get_env("GUILD_ID") |> String.to_integer
  @open_category_id System.get_env("OPEN_CATEGORY_ID") |> String.to_integer
  @closed_category_id System.get_env("CLOSED_CATEGORY_ID") |> String.to_integer
  @board_channel_id System.get_env("QUESTION_BOARD_CHANNEL_ID") |> String.to_integer

  def handle(%{content: @prefix <> "create " <> name} = msg) do
    {:ok, channels} = Nostrum.Api.get_guild_channels(msg.guild_id)
    closed_channels = channels |> Enum.filter(fn channel -> channel.parent_id == @closed_category_id end)
    case closed_channels do
      [] -> send_message msg, "空きチャンネルがありません。管理者にご連絡ください。"
      [first | _rest] ->
        Repo.transaction(fn ->
          with {:ok} <- check_duplicate(first),
          {:ok, question} <- create_question(msg, name, first),
          {:ok, question_message} <- send_question_message(msg, name, question, first),
          {:ok, channel} <- edit_channel(msg, name, first),
          {:ok, info_message} <- send_info_message(msg, question_message, name, question, first),
          {:ok, question_info} <- create_question_info(question_message, question, info_message)
          do
            send_notice_message(msg, first)
          else
            {:error, e} -> send_message(msg, "エラーが発生しました。再度お試しください。")
                Repo.rollback(e)
          end
        end)
    end
  end

  def edit_channel(msg, name, alloc_channel) do
    Nostrum.Api.modify_channel(alloc_channel.id, name: name, parent_id: @open_category_id)
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

  def send_info_message(msg, question_message, name, question, alloc_channel) do
    IO.inspect msg
    embed = %Nostrum.Struct.Embed{}
    |> put_title(name)
    |> put_author(~s/ID:#{question.id}/, "", "")
    |> put_description(if question.content == nil, do: "なし", else: question.content)
    |> put_field("投稿者", ~s/#{msg.author.username}##{msg.author.discriminator} (<@#{msg.author.id}>)/)
    |> put_field("リンク", ~s/[最初のメッセージ](https:\/\/discord.com\/channels\/#{@guild_id}\/#{question_message.channel_id}\/#{question_message.id})/)

    Nostrum.Api.create_message(@board_channel_id, embed: embed)
  end

  def create_question_info(msg, question, info_message) do
    %Dqs.QuestionInfo{
      original_message_id: msg.id,
      info_message_id: info_message.id,
      question: question
    } |> Repo.insert()
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
