defmodule Dqs.Question do
  use Ecto.Schema

  schema "question" do
    field :issuer_id, :integer
    field :name, :string
    field :content, :string
    field :status, :string
    field :tag, {:array, :string}
  end
end
