defmodule Dqs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Dqs.Consumer,
      Dqs.Repo,
      {Cachex, name: :ratelimit}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dqs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
