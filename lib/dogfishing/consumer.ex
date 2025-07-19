defmodule Dogfishing.Consumer do
  @behaviour Nostrum.Consumer

  alias Nostrum.Api.Message
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!hello" ->
        {:ok, _message} = Message.create(msg.channel_id, "Hello from Elixir!")

      _ ->
        :ignore
    end
  end

  def handle_event({:READY, _msg, _ws_state}) do
    command = %{
      name: "next",
      description: "start the next dogfish"
    }

    Nostrum.Api.ApplicationCommand.create_guild_command("1334804544596738058", command)
  end

  def handle_event({:INTERACTION_CREATE, %Interaction{data: %{name: "next"}} = interaction, _ws_state}) do
  response = %{
    type: 4,  # ChannelMessageWithSource
    data: %{
      content: "testing"
    }
  }
  Api.Interaction.create_response(interaction, response)
  end
  # Ignore any other events
  def handle_event(_), do: :ok
end
