defmodule Server do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    :ets.new(:users,[:set, :public, :named_table])
    :ets.new(:following,[:set, :public, :named_table])
    :ets.new(:subscription,[:set, :public, :named_table])
    :ets.new(:tweets,[:set, :public, :named_table])
    :ets.new(:reverse_entry,[:set, :public, :named_table])
    {:ok,%{}}
  end

  def handle_call({:get_my_followers, user_id}, _from, state) do
    [{_, existing_users_following }] = :ets.lookup(:subscription, user_id)
    {:reply, existing_users_following, state}
  end

  def handle_call({:get_my_subscribeto, user_id}, _from, state) do
    [{_, existing_users_following }] = :ets.lookup(:following, user_id)
    {:reply, existing_users_following, state}
  end

  def handle_call({:register_user, pid, user_id},from,state) do
    register_user(pid,user_id)
    {:reply,from,state}
  end

  def handle_call({:delete_user, user_id},from,state) do
    delete_user(user_id)
    {:reply,from,state}
  end

  def handle_call({:get_user_status, user_id}, _from, state) do
    [{_,record}] = :ets.lookup(:users, user_id)
    {:reply, record, state}
  end

  def handle_call({:subscribe_to_user, target_user_id, source_user_id}, from , state) do

    if (isUserValid(target_user_id) == 1 and isUserValid(source_user_id) == 1) do

      ## add the source user as a subscriber to target
      [{_, existing_subscription }] = :ets.lookup(:subscription, target_user_id)
      existing_subscription = [source_user_id | existing_subscription]
      :ets.insert(:subscription,{target_user_id, existing_subscription})

      ## add the target as a user whom the source is following.
      [{_, existing_users_following }] = :ets.lookup(:following, source_user_id)
      existing_users_following = [target_user_id | existing_users_following]
      :ets.insert(:following,{source_user_id, existing_users_following})

    end
    {:reply, from, state }
  end

  def handle_call({:log_in, user_id}, from, state) do
    log_in(user_id)
    {:reply, from, state}
  end

  def handle_call({:log_off, user_id},from, state) do
    log_off(user_id)
    {:reply, from, state}
  end

  def handle_cast({:post_tweet, username, tweetmsg}, state) do
    user_tweet_entry = :ets.lookup(:tweets, username)
    tweet_list = elem(Enum.at(user_tweet_entry,0), 1)
    :ets.insert(:tweets, {username, [tweetmsg | tweet_list]})
    subscriber_entry = :ets.lookup(:subscription, username)
    subscriber_list = elem(Enum.at(subscriber_entry,0), 1)
    Enum.each(subscriber_list, fn subscriber_client ->
      subscriber_pid_entry = :ets.lookup(:users, subscriber_client)
      subscriber_pid = elem(elem(Enum.at(subscriber_pid_entry,0), 1),0)

      # check if subscriber is connected
      if(is_active(subscriber_client)==1) do
        GenServer.cast(subscriber_pid,{:live_feed, tweetmsg})
      end
    end)
    {:noreply,state}
  end

  def handle_cast({:add_reverse_entry, key, tweetmsg}, state) do
    reverse_entry = :ets.lookup(:reverse_entry, key)
    tweet_list =
    if reverse_entry == nil or reverse_entry == [] do
      []
    else
      elem(Enum.at(reverse_entry,0), 1)
    end

    :ets.insert(:reverse_entry, {key, [tweetmsg | tweet_list]})
    {:noreply,state}
  end

  def handle_call({:query_reverse_Entry, key}, from,state) do
    reverse_entry = :ets.lookup(:reverse_entry, key)
    tweet_list =
      if Enum.at(reverse_entry,0)!=nil do
        elem(Enum.at(reverse_entry,0), 1)
      else
        []
      end
    {:reply,tweet_list,state}
  end

  def handle_call({:query_news_feed, username}, from,state) do
    following_entry = :ets.lookup(:following, username)
    following_list = elem(Enum.at(following_entry,0), 1)
    result =
      Enum.reduce(following_list, [], fn following_client, acc ->
        following_tweet_entry = :ets.lookup(:tweets, following_client)
        following_tweet_list = elem(Enum.at(following_tweet_entry,0), 1)
        acc =
          if following_tweet_list == nil or following_tweet_list == [] do
            acc
          else
            [{following_client,following_tweet_list } | acc]
          end
      end)

    {:reply,result,state}
  end

  defp register_user(pid,user_id) do
    :ets.insert(:users, {user_id, {pid,1}})
    :ets.insert(:following, {user_id, []})
    :ets.insert(:subscription, {user_id, []})
    :ets.insert(:tweets, {user_id, []})
  end

  defp delete_user(user_id) do
    :ets.insert(:users,{user_id,{-1,0}})
  end

  defp log_off(user_id) do
    [{_,{pid,_}}] = :ets.lookup(:users,user_id)
    :ets.insert(:users,{user_id,{pid,0}})
  end

  defp log_in(user_id) do
    [{_,{pid,_}}] = :ets.lookup(:users,user_id)
    :ets.insert(:users,{user_id,{pid,1}})
  end

  defp is_active(user_id) do
    [{_,{_,is_active}}] = :ets.lookup(:users,user_id)
    is_active
  end

  defp isUserValid(user_id) do
    resp =
    if ( :ets.lookup(:users, user_id) == [] && :ets.lookup(:following, user_id) == [] and :ets.lookup(:tweets, user_id) == [] and :ets.lookup(:subscription, user_id) == []) do
        0
    else
        1
    end
    resp
  end

end
