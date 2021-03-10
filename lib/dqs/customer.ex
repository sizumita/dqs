defmodule Dqs.Consumer do
  use Nostrum.Consumer

  alias Dqs.Command
  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    Command.on_message(msg)
  end

  def handle_event(_event) do
    :noop
  end
end
