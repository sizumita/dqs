defmodule Dqs.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    execute(
      "CREATE EXTENSION pgroonga"
    )
    execute(
      "create type question_status as enum ('open', 'closed', 'erased')"
    )

    create table(:questions) do
      add :issuer_id, :bigint
      add :name, :text
      add :content, :text
      add :status, :question_status
      add :channel_id, :bigint
      add :tag, {:array, :string}

      timestamps()
    end

    execute(
      "CREATE INDEX pgroonga_content_index ON questions USING pgroonga (content);"
    )
  end
end
