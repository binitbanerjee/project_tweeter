defmodule Clients do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    [user_id,server_id] = args
    state = %{
      server_id: server_id,
      id: user_id,
      news_feed: []
    }
    GenServer.call(server_id, {:register_user, self(), user_id})
    {:ok, state}
  end

  def handle_call({:subscribe, subscribe_to_ids}, from, state) do
    {:ok, server_pid} = Map.fetch(state,:server_id)
    {:ok, self_id} = Map.fetch(state,:id)
    Enum.map(subscribe_to_ids, fn id ->
      GenServer.call(server_pid,{:subscribe_to_user, id, self_id})
    end)
    {:reply, from, state}
  end

  def handle_call({:get_my_followers}, _from, state) do
    {:ok, server_pid} = Map.fetch(state,:server_id)
    {:ok, self_id} = Map.fetch(state,:id)
    existing_users_following = GenServer.call(server_pid, {:get_my_followers, self_id})
    {:reply, existing_users_following, state}
  end

  def handle_call({:get_my_subscribeto}, _from, state) do
    {:ok, server_pid} = Map.fetch(state,:server_id)
    {:ok, self_id} = Map.fetch(state,:id)
    existing_users_following  = GenServer.call(server_pid, {:get_my_subscribeto, self_id})
    {:reply, existing_users_following, state}
  end

  def handle_call({:log_in}, from, state) do
    {:ok, server_pid} = Map.fetch(state,:server_id)
    {:ok, self_id} = Map.fetch(state,:id)
    GenServer.call(server_pid, {:log_in, self_id})
    tweet_list = GenServer.call(server_pid,{:query_news_feed, self_id})
    tweet_list =
      if tweet_list == nil do
        []
      else
        tweet_list
      end
    state = %{
        server_id: server_pid,
        id: self_id,
        news_feed: tweet_list
      }
    # IO.puts("updated feed after logging back in : #{inspect tweet_list}")
    {:reply, from, state}
  end

  def handle_call({:log_off}, from, state) do
    {:ok, server_pid} = Map.fetch(state,:server_id)
    {:ok, self_id} = Map.fetch(state,:id)
    GenServer.call(server_pid, {:log_off, self_id})

    {:reply, from, state}
  end



  def handle_call({:query_hashtag, hashtag}, _from, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    tweet_list = GenServer.call(server_pid,{:query_reverse_Entry, hashtag})
    tweet_list =
    if tweet_list == nil do
      []
    else
      tweet_list
    end
    {:reply, tweet_list, state}
  end

  def handle_call({:query_mentions}, _from, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    tweet_list = GenServer.call(server_pid,{:query_reverse_Entry, username})
    tweet_list =
    if tweet_list == nil do
      []
    else
      tweet_list
    end
    {:reply, tweet_list, state}
  end

  def handle_call({:query_news_feed}, _from, state) do
    {:ok, server_pid} = Map.fetch(state, :server_id)
    {:ok, username} = Map.fetch(state, :id)
    tweet_list = GenServer.call(server_pid,{:query_news_feed, username})
    tweet_list =
      if tweet_list == nil do
        []
      else
        tweet_list
      end
    state = %{
        server_id: server_pid,
        id: username,
        news_feed: tweet_list
      }
    {:reply, tweet_list, state}
  end

  def handle_cast({:register, server_id, user_id}, _state) do
    state = %{
      server_id: server_id,
      id: Enum.join(["@", user_id]),
      news_feed: []
    }
    {:noreply, state}
  end

  def handle_cast({:tweet_post, tweet_msg}, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    words = String.split(tweet_msg)
    {hashtag_list, user_tag_list} =
    Enum.reduce(words,{[],[]},fn word, acc ->
      acc=
      if String.at(word,0) == "#" do
        hashlist = elem(acc,0)
        userlist = elem(acc,1)
        {[word|hashlist],userlist}
      else
        acc
      end
      if String.at(word,0) == "@" do
        hashlist = elem(acc,0)
        userlist = elem(acc,1)
        {hashlist,[word|userlist]}
      else
        acc
      end
    end)

    if hashtag_list != [] do
      Enum.each(hashtag_list, fn hashtag ->
        GenServer.cast(server_pid,{:add_reverse_entry, username, hashtag, tweet_msg})
      end)
    end
    if user_tag_list != [] do
      Enum.each(user_tag_list, fn user_tag ->
        GenServer.cast(server_pid,{:add_reverse_entry, username, user_tag, tweet_msg})
      end)
    end
    GenServer.cast(server_pid,{:post_tweet, username, tweet_msg})
    {:noreply, state}
  end

  def handle_cast({:live_feed, tweetmsg}, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    {:ok, feed} =Map.fetch(state, :news_feed)
    feed = [{username, tweetmsg}|feed]
    state = %{
      server_id: server_pid,
      id: username,
      news_feed: feed
    }
    multidimension_coin_toss = :rand.uniform(300)
    if multidimension_coin_toss >= 260 do
      #placeholder: add call to retweet
      tweet_for_retweeting = Utility.get_random_tweet_but_not_my_own(feed, username, {})
      {user_id_for_retweeting, tweets} = tweet_for_retweeting
      tweet = Enum.random(tweets)

      IO.puts("#{inspect tweet} by #{inspect user_id_for_retweeting}")
    end
    {:noreply, state}
  end

end
