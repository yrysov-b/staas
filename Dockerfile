FROM elixir:1.14-alpine

RUN apk update 

WORKDIR /app

COPY mix.exs mix.lock ./

RUN mix local.hex --force && mix local.rebar --force

RUN mix deps.get

COPY . .

RUN mix compile

CMD ["mix", "run"]
