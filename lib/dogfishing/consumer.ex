defmodule Dogfishing.Consumer do
  @behaviour Nostrum.Consumer

  alias Nostrum.Api.Message
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction

  def current_page do
    current_page = :ets.lookup(:dogfishing, :current_page)
    if current_page |> Enum.empty? do
      :ets.insert(:dogfishing, {:current_page, nil})
      current_page()
    else
      current_page
      |> hd
      |> elem(1)
    end
  end

  def set_current_page(page) do
    current_page()
    :ets.insert(:dogfishing, {:current_page, page})
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    if is_map(current_page()) && !message.author.bot do
      dist = message.content
      |> String.jaro_distance(current_page().title)
      page = current_page()
      set_current_page(nil)
      response = %{
        flags: 32768,
        components: [
          %{
            type: 10,
            content: "test"
          },
          %{
            type: 1,
            components: [
              %{
                type: 2,
                label: "Click me!",
                style: 1,
                custom_id: "clicked_me"
              }
            ]
          }
        ]
      }


      Message.create(message.channel_id, response)#"The word was `#{page.title}`. Jaro distance: #{dist}")
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
      content: "Searching for a good article..."
    }})
    #Api.Interaction.create_response(interaction, %{type: 4, data: %{
    #  content: "test3"
    #}})
    #%{type: 4, data: %{
    #  flags: 32768,
    #  components: [
    #    %{
    #      type: 10,
    #      content: "test"
    #    }
    #  ]
    #}})

    page = Wikipedia.random_article(fn page -> page.views > 10000 end, 0, fn accumulator ->
      if rem(accumulator, 10) == 0 do
        Api.Message.create(interaction.channel_id, "Searched across #{accumulator} articles.")
      end
    end)

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
     flags: 32768,
     components: buttons
    }

    set_current_page(page)
    page.categories
    |> Enum.reduce("", fn category, accumulator ->
      "`#{category}` #{accumulator}"
    end)
    |> then(fn categories_text ->
      Api.Message.create(interaction.channel_id, response)
    end)
  end
  # Ignore any other events
  def handle_event(_), do: :ok
end
