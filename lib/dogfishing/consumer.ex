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
    Api.Interaction.create_response(interaction, %{type: 4, data: %{
      content: "test3"
    }})
    #%{type: 4, data: %{
    #  flags: 32768,
    #  components: [
    #    %{
    #      type: 10,
    #      content: "test"
    #    }
    #  ]
    #}})
    {:ok, _, _, page} = Wikipedia.random_article
    buttons = page.categories
    |> Enum.map(fn category ->
      %{
        type: 2,
        label: category,
        style: 5,
        url: URI.encode("https://en.wikipedia.org/wiki/Category:" <> category)
      }
    end)
    |> Enum.chunk_every(5)
    |> Enum.map(fn row ->
      %{
        type: 1,
        components: row
      }
    end)
    response = %{
      type: 4,
      data: %{
        flags: 32768,
        components: buttons
      }
    }
    #:timer.sleep(1000)
    Api.Interaction.edit_response(interaction, %{type: 4, data: %{
      content: "test2"
    }})
  end
  # Ignore any other events
  def handle_event(_), do: :ok
end
