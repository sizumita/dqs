defmodule Dqs.Command do
  alias Dqs.Repo

  def on_message(%{content: "!create"} = msg) do
    Repo.insert(
      %Dqs.Question{
        issuer_id: msg.author.id,
        name: "test question",
        content: "テストがしたい",
        status: "open",
        channel_id: msg.channel_id,
        tag: ["test"]
      }
    ) |> IO.inspect
  end
end
