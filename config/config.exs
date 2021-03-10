use Mix.Config


config :nostrum,
       token: System.get_env("BOT_TOKEN"),
       num_shards: :auto,
       gateway_intents: [
         :guilds,
         :guild_members,
         :guild_messages
       ]


config :dqs, ecto_repos: [Dqs.Repo]

config :dqs, Dqs.Repo,
       database: "dqs",
       username: System.get_env("POSTGRES_USER"),
       password: System.get_env("POSTGRES_PASSWORD"),
       hostname: "0.0.0.0",
       pool_size: 10

