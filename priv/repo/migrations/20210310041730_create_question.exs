defmodule Dqs.Repo.Migrations.CreateQuestion do
  use Ecto.Migration

  def change do
    execute(
      "create type question_status as enum ('open', 'close', 'erased')"
    )

    create table(:question) do
      add :issuer_id, :bigint
      add :name, :string
      add :content, :string
      add :status, :question_status
      add :tag, {:array, :string}
    end
  end
end
