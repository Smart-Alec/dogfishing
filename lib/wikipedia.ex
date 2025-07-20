defmodule Wikipedia do
  @endpoint "https://en.wikipedia.org/w/api.php?format=json&"
  @cache :wikipedia_cache

  def request(uri) do
    Req.get!(@endpoint <> uri).body
  end

  def random_id do
    if :ets.info(@cache) == :undefined do
      :ets.new(@cache, [:named_table])
      random_id()
    else
      random_ids = :ets.lookup(@cache, :random_ids)
      if Enum.empty?(random_ids) || random_ids |> hd |> elem(1) |> Enum.empty? do
        #generate a new set of random ids
        random_ids = case request("action=query&generator=random&grnnamespace=0&grnlimit=500") do
          %{"query" => %{"pages" => pages}} -> pages
          _ -> :error
        end
        |> Enum.map(fn page ->
          {id, _} = page
          id
        end)

        :ets.insert(@cache, {:random_ids, random_ids})
        random_id()
      else
        #pop a new id
        [random_id | random_ids] = random_ids |> hd |> elem(1)
        :ets.insert(@cache, {:random_ids, random_ids})
        random_id
      end
    end
  end

  def metadata(id) do
    page = case request("action=query&prop=pageviews%7Ccategories%7Cextracts&clshow=!hidden&exintro=true&explaintext=true&pageids=#{id}") do
      %{"query" => %{"pages" => pages}} ->
        Map.to_list(pages)
        |> hd
        |> elem(1)
      _ -> :error
    end

    %{
      title: page["title"],
      summary: page["extract"],
      views: page["pageviews"]
      |> Map.to_list
      |> Enum.reduce(0, fn date, accumulator ->
        accumulator + ((elem date, 1) || 0)
      end),
      categories: page["categories"]
      |> Enum.map(fn category ->
        category["title"]
        |> String.trim("Category:")
      end)
    }
  end

  def random_article do
    #use article view threshhold based on ETS :threshhold variable
    unless :ets.info(@cache) == :undefined do
      :ets.lookup(@cache, :threshhold)
      |> hd
      |> elem(1)
      |> then(fn threshhold ->
        random_article(fn page -> page.views > threshhold end, 0, fn _ -> nil end)
      end)
    else
      random_article(fn page -> page.views > 100 end, 0, fn _ -> nil end)
    end
  end

  def random_article(filter, accumulator, callback) do
    page = metadata(random_id())
    callback.(accumulator)
    if filter.(page) do
      page
    else
      random_article(filter, accumulator + 1, callback)
    end
  end
end
