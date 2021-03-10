import Config


config :nostrum,
       token: System.get_env("BOT_TOKEN"),
       num_shards: :auto,
       gateway_intents: [
         :guilds,
         :guild_members,
         :guild_messages
       ]
