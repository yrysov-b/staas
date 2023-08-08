FROM elixir:1.14-alpine

RUN apt-get update 

WORKDIR /app

COPY mix.exs mix.lock ./

RUN mix local.hex --force && mix local.rebar --force

RUN mix deps.get

COPY . .

RUN mix compile

CMD ["mix", "phx.server"]
