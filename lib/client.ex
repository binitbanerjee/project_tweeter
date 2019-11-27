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

  def handle_cast({:register, server_id, user_id}, _state) do
    state = %{
      server_id: server_id,
      id: Enum.join(["@", user_id]),
      news_feed: []
    }

    {:noreply, state}
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

  def handle_cast({:register, server_id, user_id}, _state) do
    state = %{
      server_id: server_id,
      id: Enum.join(["@", user_id]),
      news_feed: []
    }

    {:noreply, state}
  end

  def handle_cast({:tweet_post, tweet_msg, hashtag, user_tag}, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    # IO.puts(" #{tweet_msg} ")
    if hashtag != "" do
      GenServer.cast(server_pid,{:add_reverse_entry, hashtag, tweet_msg})
    end
    if user_tag != "" do
      GenServer.cast(server_pid,{:add_reverse_entry, user_tag, tweet_msg})
    end
    GenServer.cast(server_pid,{:post_tweet, username, tweet_msg})
    {:noreply, state}
  end

  def handle_cast({:live_feed, username, tweetmsg}, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    {:ok, feed} =Map.fetch(state, :news_feed)
    feed = [{username, tweetmsg}|feed]
    state = %{
      server_id: server_pid,
      id: username,
      news_feed: feed
    }
    {:noreply, state}
  end

  def handle_call({:query_hashtag, hashtag}, from, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    tweet_list = GenServer.call(server_pid,{:query_reverse_Entry, hashtag})
    tweet_list =
    if tweet_list == nil do
      []
    else
      tweet_list
    end
    {:reply, from, state}
  end

  def handle_call({:query_mentions}, from, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    tweet_list = GenServer.call(server_pid,{:query_reverse_Entry, username})
    tweet_list =
    if tweet_list == nil do
      []
    else
      tweet_list
    end
    {:reply, from, state}
  end

  def handle_call({:query_news_feed, hashtag}, from, state) do
    {:ok, server_pid} =Map.fetch(state, :server_id)
    {:ok, username} =Map.fetch(state, :id)
    tweet_list = GenServer.call(server_pid,{:query_reverse_Entry, username})
    tweet_list =
    if tweet_list == nil do
      []
    else
      tweet_list
    end
    {:reply, from, state}
  end

end
