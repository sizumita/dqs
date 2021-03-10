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
       username: "postgres",
       password: "postgres",
       hostname: "0.0.0.0",
       show_sensitive_data_on_connection_error: true,
       pool_size: 10

