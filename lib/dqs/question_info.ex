defmodule Dqs.QuestionInfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "question_info" do
    field :original_message_id, :integer
    field :info_message_id, :integer
    belongs_to :question, Dqs.Question
  end
end
