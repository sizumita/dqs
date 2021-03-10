defmodule Dqs.Repo do
  use Ecto.Repo,
      otp_app: :dqs,
      adapter: Ecto.Adapters.Postgres
end
