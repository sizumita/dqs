defmodule Dqs.Command do
  alias Dqs.Cache
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild.Member
  @prefix Application.get_env(:dqs, :prefix)
  @open_category_id Application.get_env(:dqs, :open_category_id)
  require Dqs.Macro
  import Dqs.Macro

  def handle(%{content: @prefix <> "set " <> _} = msg) do
    limited_command msg do
      Dqs.Command.Modify.handle(msg)
    end
  end

  def handle(%{content: @prefix <> "tag " <> _} = msg) do
    limited_command msg do
      Dqs.Command.Tag.handle(msg)
    end
  end

  def handle(%{content: @prefix <> "close"} = msg) do
    limited_command msg do
      Dqs.Command.Close.handle(msg)
    end
  end

  def handle(%{content: @prefix <> "trash"} = msg) do
    guild = GuildCache.get!(msg.guild_id)
    member = Map.get(guild.members, msg.author.id)
    member_perms = Member.guild_permissions(member, guild)
    if :manage_channels in member_perms do
      limited_command msg do
        Dqs.Command.Trash.handle(msg)
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
<##{Application.get_env(:dqs, :board_channel_id)}>に質問のタイトルを投稿すると、自動的に質問チャンネルが作成されます。

コマンド一覧
```
#{@prefix}help -> このメッセージを表示します。

#{@prefix}set title [タイトル] -> タイトルを新しく設定します。
#{@prefix}set content [内容] -> 質問の内容を設定します。
(返信つきで) #{@prefix}set content -> 返信元のメッセージを質問の内容として設定します。
#{@prefix}tag add [タグ] -> タグを追加します。タグは半角の空白で区切って複数指定できます。
#{@prefix}tag remove [タグ] -> タグを削除します。タグは半角の空白で区切って複数指定できます。

#{@prefix}find [検索する文字列] -> 質問を検索します。質問のタイトルから検索が可能です。AND,ORやマイナス検索が可能です。
#{@prefix}find tag [検索するタグ] -> タグを検索します。空白を挟んで複数のタグを指定すると、AND検索になります。

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
