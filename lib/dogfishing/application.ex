defmodule Dogfishing.Application do
  use Application

  @impl true
  def start(_type, _args) do
    :ets.new(:dogfishing, [:named_table, :public])

    bot_options = %{
      name: Dogfishing,
      consumer: Dogfishing.Consumer,
      intents: :all,
      wrapped_token: fn ->
        System.get_env("BOT_TOKEN")
      end
    }

    children = [
      Dogfishing.Scorekeeper,
      {Nostrum.Bot, bot_options}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
