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

  def api_handler() do
      receive do
          {interaction, data} ->
            {_, messages} = Process.info(self(), :message_queue_len)
            if messages > 0 do #we're already backed up! just skip it
              api_handler()
            else
              Api.Interaction.edit_response(interaction, data)
              api_handler()
            end
          _ -> nil
      end
  end

  def start_new_game(interaction) do
    #start inital response
    Api.Interaction.create_response(interaction, %{type: 4, data: %{
      flags: 32768,
      components: [
        %{
          type: 10,
          content: "Searching 0 articles..."
        }
      ]
    }})

    #spawn seperate process so we can send a bunch of messages
    #this process will queue up messages in its mailbox and
    #automatically skip them if the queue grows too long
    api_sender = spawn(&Dogfishing.Consumer.api_handler/0)

    page = Wikipedia.random_article(fn page ->
      #add filters here
      page.views > 10000
      && 1
    end, 0, fn accumulator ->
      data = %{
        flags: 32768,
        components: [
          %{
            type: 10,
            content: "Searching #{accumulator} articles..."
          }
        ]
      }

      send(api_sender, {interaction, data})
    end)

    #generate layout for final screen showing all categories
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
    send(api_sender, {interaction, response})
    Process.exit(api_sender, :normal)
  end

  def generate_final_screen(message) do
    if is_map(current_page()) && !message.author.bot do
      page = current_page()
      set_current_page(nil)
      response = %{
        flags: 32768,
        components: [
          %{
            type: 10,
            content: "The article was `#{page.title}`!",
            label: "The article was `#{page.title}`!"
          },
          %{
            type: 1,
            components: [
              %{
                type: 2,
                label: "#{page.title} on Wikipedia",
                style: 5,
                url: URI.encode("https://en.wikipedia.org/wiki/" <> page.title)
              }
            ]
          }
        ]
      }


      Message.create(message.channel_id, response)
      Message.create(message.channel_id, score_buttons())
    end
  end

  def score_buttons do
    %{
      flags: 32768,
      components: [
        %{
          type: 1,
          components: [
            %{
              type: 2,
              label: "👍 #{Dogfishing.Scorekeeper.right()}",
              style: 3,
              custom_id: "right"
            },
            %{
              type: 2,
              label: "👎 #{Dogfishing.Scorekeeper.wrong()}",
              style: 4,
              custom_id: "wrong"
            },
            %{
              type: 2,
              label: "➡️",
              style: 1,
              custom_id: "next"
            }
          ]
        }
      ]
    }
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    generate_final_screen(message)
  end

  def handle_event({:READY, _msg, _ws_state}) do
    command = %{
      name: "start",
      description: "Start playing Dogfishing!"
    }

    #To overwrite commmands
    #Nostrum.Api.ApplicationCommand.bulk_overwrite_guild_commands "1334804544596738058", []

    Nostrum.Api.ApplicationCommand.create_guild_command("1334804544596738058", command)
  end

  def handle_event({:INTERACTION_CREATE, %Interaction{data: %{custom_id: "right"}} = interaction, _ws_state}) do
    Dogfishing.Scorekeeper.increment_right()
    #acknowledge request
    Api.Interaction.create_response(interaction, %{type: 6, data: %{flags: 32768}})
    #then update button
    Api.Interaction.edit_response(interaction, score_buttons())
  end

  def handle_event({:INTERACTION_CREATE, %Interaction{data: %{custom_id: "wrong"}} = interaction, _ws_state}) do
    Dogfishing.Scorekeeper.increment_wrong()
    #acknowledge request
    Api.Interaction.create_response(interaction, %{type: 6, data: %{flags: 32768}})
    #then update button
    Api.Interaction.edit_response(interaction, score_buttons())
  end

  #handle new games via button
  def handle_event({:INTERACTION_CREATE, %Interaction{data: %{custom_id: "next"}} = interaction, _ws_state}), do: start_new_game(interaction)
  #or command
  def handle_event({:INTERACTION_CREATE, %Interaction{data: %{name: "start"}} = interaction, _ws_state}), do: start_new_game(interaction)
  #ignore any other events
  def handle_event(_), do: :ok
end
