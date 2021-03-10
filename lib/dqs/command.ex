defmodule Dqs.Command do
  alias Dqs.Cache
  @prefix System.get_env("PREFIX")
  @open_category_id System.get_env("OPEN_CATEGORY_ID")
                    |> String.to_integer

  def handle(%{content: @prefix <> "create " <> _name} = msg) do
    Dqs.Command.Create.handle(msg)
  end

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

  def handle(%{content: @prefix <> "help"} = msg) do
    content = ~s/
```
#{@prefix}help -> このメッセージを表示します。

#{@prefix}create [タイトル] -> 新しく質問を作成します。

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
