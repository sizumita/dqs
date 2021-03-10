defmodule Dqs.Repo.Migrations.CreateQuestionInfo do
  use Ecto.Migration

  def change do
    create table(:question_info) do
      add :original_message_id, :bigint
      add :info_message_id, :bigint
      add :question_id, references(:questions)

      timestamps()
    end

    create unique_index(:question_info, [:question_id])
  end
end
