defmodule Dqs.Cache do
  alias Nostrum.Cache.{ChannelCache, GuildCache, UserCache}
  alias Nostrum.Api
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Channel
  import Nostrum.Snowflake, only: [is_snowflake: 1]

  defp get_cached_with_fallback(id, cache, api) do
    case cache.(id) do
      {:ok, _} = data -> data
      {:error, _} -> api.(id)
    end
  end

  def get_user(id) when is_snowflake(id) do
    get_cached_with_fallback(id, &UserCache.get/1, &Api.get_user/1)
  end

  def get_channel(id) when is_snowflake(id) do
    get_cached_with_fallback(id, &ChannelCache.get/1, &Api.get_channel/1)
  end

  def get_guild(id) when is_snowflake(id) do
    get_cached_with_fallback(id, &GuildCache.get/1, &Api.get_guild/1)
  end
end