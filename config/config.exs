import Config

config :staas, uri: System.get_env("REDIS_URL", "redis://localhost:6379")
