defmodule Dqs.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :issuer_id, :integer
    field :name, :string
    field :content, :string
    field :status, :string
    field :channel_id, :integer
    field :tag, {:array, :string}, default: []

    timestamps()
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:issuer_id, :name, :status])
    |> validate_required([:issuer_id, :name, :status])
  end
end
