FROM elixir:1.11.2

ENV MIX_HOME=/opt/mix


WORKDIR /bot
ADD mix.exs /bot

RUN mix local.rebar --force && mix local.hex --force && mix deps.get

RUN mix deps.compile

ADD .env /bot
ADD config /bot/config

ADD lib /bot/lib
ADD test /bot/test


RUN mix compile

CMD ["mix", "run", "--no-halt"]
