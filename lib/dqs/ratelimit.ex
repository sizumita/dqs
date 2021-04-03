defmodule Dqs.Ratelimit do
  def ratelimit?(channel_id) do
    IO.inspect Cachex.get!(:ratelimit, to_string(channel_id))
    case Cachex.get!(:ratelimit, to_string(channel_id)) do
      nil -> false
      r -> r
    end
  end

  def wait_ratelimit(channel_id, long) do
    IO.inspect Cachex.put(:ratelimit, to_string(channel_id), true)
    :timer.sleep(long)
    IO.inspect Cachex.put(:ratelimit, to_string(channel_id), false)
  end
end
