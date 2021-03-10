defmodule Dqs.Consumer do
  use Nostrum.Consumer

  alias Dqs.Command
  alias Nostrum.Api
  @prefix System.get_env("PREFIX")

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, %{author: %{bot: nil}, content: @prefix <> _command} = msg, _ws_state}) do
    Command.handle(msg)
  end

  def handle_event(_event) do
    :noop
  end
end
