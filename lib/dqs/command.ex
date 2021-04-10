defmodule Dqs.Command do
  alias Dqs.Cache
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild.Member
  @prefix Application.get_env(:dqs, :prefix)
  @open_category_id Application.get_env(:dqs, :open_category_id)

  def handle(%{content: @prefix <> "set " <> _} = msg) do
    {:ok, channel} = Cache.get_channel(msg.channel_id)
    if channel.parent_id == @open_category_id do
      Dqs.Command.Modify.handle(msg)
    else
      create_message(msg.channel_id, "このチャンネルでは使用できません。")
    end
  end

  def handle(%{content: @prefix <> "tag " <> _} = msg) do
    {:ok, channel} = Cache.get_channel(msg.channel_id)
    if channel.parent_id == @open_category_id do
      Dqs.Command.Tag.handle(msg)
    else
      create_message(msg.channel_id, "このチャンネルでは使用できません。")
    end
  end

  def handle(%{content: @prefix <> "close"} = msg) do
    {:ok, channel} = Cache.get_channel(msg.channel_id)
    if channel.parent_id == @open_category_id do
      Dqs.Command.Close.handle(msg)
    else
      create_message(msg.channel_id, "このチャンネルでは使用できません。")
    end
  end

  def handle(%{content: @prefix <> "trash"} = msg) do
    guild = GuildCache.get!(msg.guild_id)
    member = Map.get(guild.members, msg.author.id)
    member_perms = Member.guild_permissions(member, guild)
    if :manage_channels in member_perms do
      {:ok, channel} = Cache.get_channel(msg.channel_id)
      if channel.parent_id == @open_category_id do
        Dqs.Command.Trash.handle(msg)
      else
        create_message(msg.channel_id, "このチャンネルでは使用できません。")
      end
    else
      create_message(msg.channel_id, ~s/<@#{msg.author.id}>, チャンネル管理権限を持っていないため使用できません。/)
    end
  end

  def handle(%{content: @prefix <> "find" <> _} = msg) do
    Dqs.Command.Search.handle(msg)
  end

  def handle(%{content: @prefix <> "help"} = msg) do
    content = ~s/
<##{System.get_env("QUESTION_CHANNEL_ID")}>に質問のタイトルを投稿すると、自動的に質問チャンネルが作成されます。

コマンド一覧
```
#{@prefix}help -> このメッセージを表示します。

#{@prefix}title [タイトル] -> タイトルを新しく設定します。
#{@prefix}content [内容] -> 質問の内容を設定します。
(返信つきで) #{@prefix}content -> 返信元のメッセージを質問の内容として設定します。
#{@prefix}tag add [タグ] -> タグを追加します。タグは半角の空白で区切って複数指定できます。
#{@prefix}tag remove [タグ] -> タグを削除します。タグは半角の空白で区切って複数指定できます。

#{@prefix}close -> 質問を終了します。
```
/
    Nostrum.Api.create_message(msg.channel_id, content)
  end

  def handle(_msg) do
    :noop
  end

  defp create_message(channel_id, message) do
    Nostrum.Api.create_message(channel_id, message)
  end
end
