defmodule Dqs.QuestionInfo do
  use Ecto.Schema

  schema "question_info" do
    field :original_message_id, :integer
    field :info_message_id, :integer
    belongs_to :question, Dqs.Question

    timestamps()
  end
end
