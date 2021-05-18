import Config


config :nostrum,
       token: System.get_env("BOT_TOKEN"),
       num_shards: :auto,
       gateway_intents: :all


config :dqs, ecto_repos: [Dqs.Repo]

config :dqs, Dqs.Repo,
       database: "dqs",
       username: System.get_env("POSTGRES_USER"),
       password: System.get_env("POSTGRES_PASSWORD"),
       hostname: System.get_env("POSTGRES_HOSTNAME"),
       pool_size: 10

config :dqs, :board_channel_id, System.get_env("QUESTION_BOARD_CHANNEL_ID") |> String.to_integer
config :dqs, :closed_category_id, System.get_env("CLOSED_CATEGORY_ID") |> String.to_integer
config :dqs, :open_category_id, System.get_env("OPEN_CATEGORY_ID") |> String.to_integer
config :dqs, :prefix, System.get_env("PREFIX")
config :dqs, :guild_id, System.get_env("GUILD_ID")



