defmodule Dqs.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    execute(
      "create type question_status as enum ('open', 'closed', 'erased')"
    )

    create table(:questions) do
      add :issuer_id, :bigint
      add :name, :string
      add :content, :string
      add :status, :question_status
      add :channel_id, :bigint
      add :tag, {:array, :string}

      timestamps()
    end
  end
end
