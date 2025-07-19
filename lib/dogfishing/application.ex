defmodule Dogfishing.Application do
  use Application

  @impl true
  def start(_type, _args) do
    bot_options = %{
      name: Dogfishing,
      consumer: Dogfishing.Consumer,
      intents: :all,
      wrapped_token: fn ->
        "MTM5NjAyMDQ2MDcwOTIxNjM2Nw.GrO0xg.65VCn9V7Ma7_P574aez3kchiYI6P4l9BOF79ZY"
      end
    }

    children = [
      {Nostrum.Bot, bot_options}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
