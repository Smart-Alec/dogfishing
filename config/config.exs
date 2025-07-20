import Config

if config_env() in [:dev, :test] do
  import_config ".env.exs"
end

config :nostrum, youtubedl: false
config :nostrum, streamlink: false
