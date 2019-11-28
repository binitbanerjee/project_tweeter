defmodule Utility do
  def get_random(all, self, count, results) do
    if(length(results) < count) do
      random = Enum.random(all)
      results =
        if(random != self) do
          [random|results]
        else
          results
        end
      get_random(all, self, count, results)
      else
        results
    end
  end

  def get_random_user(all, self, target) do
    if(target=="") do
      random = Enum.random(all)
      if(self == random) do
        get_random_user(all,self,"")
      else
        get_random_user(all, self, random)
      end
    else
      target
    end
  end

  def get_random_tweet(clients, self) do
    coin_toss = :rand.uniform(3)
    mention_name = get_random_user(clients, self, "")
    random_hashtag = get_hashtag()
    cond do
      coin_toss == 1 -> {"this is a random tweet" <> " " <> random_hashtag}
      coin_toss == 2 -> {"this is a random tweet with mention of"<> " "<> mention_name}
      true -> {"this is a random tweet."}
    end
  end

  def get_hashtag() do
    hashtags = ["#itIsTrending", "#yayElixir", "#whatsInaHashTag"]
    Enum.random(hashtags)
  end

  def assign_subscribers(clients, count_of_subscriber) do
    len = length(clients)
    num_followers =
      if count_of_subscriber == 0 do
        1
      else
        count_of_subscriber
      end
    client_ids = Enum.map(clients, fn {x,_}->
      x
    end)
    #clients = client_ids
    Enum.each(0..(len-1), fn index ->
      {target_id,target_pid} = Enum.at(clients, index)
      neighbors = get_random(client_ids, target_id, num_followers, [])

      GenServer.call(target_pid, {:subscribe, neighbors})
    end)
  end

  def assign_subscribers_zipf(clients) do
    len = length(clients)

    client_ids = Enum.map(clients, fn {x,_}->
      x
    end)
    #clients = client_ids
    Enum.each(0..(len-1), fn index ->
      {target_id,target_pid} = Enum.at(clients, index)
      num_followers =
        if index==0 do
          len-1
        else
          round((len-1)/index)
        end
      neighbors = get_random(client_ids, target_id, num_followers, [])

      GenServer.call(target_pid, {:subscribe, neighbors})
    end)
  end

  def get_random_tweet_but_not_my_own(tweets, self_id, match) do
    if match == {} do
      match = Enum.random(tweets)
      {id,_} = match
      if id==self_id do
        get_random_tweet_but_not_my_own(tweets, self_id, {})
      else
        get_random_tweet_but_not_my_own(tweets, self_id, match)
      end
    else
      match
    end
  end

end
