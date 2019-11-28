defmodule ClientTest do

  use ExUnit.Case
  doctest PROJ4

  defp get_random(all, self, count, results) do
    if(length(results) < count) do
      random = Enum.random(all)
      results =
        if(random!=self) do
          [random|results]
        else
          results
        end
      get_random(all, self, count, results)
      else
        results
    end

  end

  defp simulate_random_log_off_log_in(clients, count) do
    if(count>0) do
      {_, target_pid} = Enum.random(clients)
      if(Process.alive?(target_pid)) do
        GenServer.call(target_pid,{:log_off})
        Process.sleep(100)
        if(Process.alive?(target_pid)) do
          GenServer.call(target_pid,{:log_in})
          GenServer.call(target_pid, {:query_news_feed})
        end
      end
      simulate_random_log_off_log_in(clients, count-1)
    end
  end

  defp simulate_log_off_log_in(clients, user_id) do
      {_, target_pid} = Enum.random(clients)
      feed =
      if(Process.alive?(target_pid)) do
        GenServer.call(target_pid,{:log_off})
        Process.sleep(100)
        feed =
        if(Process.alive?(target_pid)) do
          GenServer.call(target_pid,{:log_in})
          GenServer.call(target_pid, {:query_news_feed})
        else
          []
        end
        feed
      else
        []
      end
  end

  defp assign_subscribers_zipf(clients, server_pid) do
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

  defp assign_subscribers(clients, server_pid) do
    len = length(clients)
    Enum.each(0..(len-1), fn index ->
      {target_id, target_pid} = Enum.at(clients, index)
      if index == 0 do
        {n1, _} = Enum.at(clients, 1)
        GenServer.call(target_pid, {:subscribe, [n1]})
      end
      if index == (len-1) do
        {n1, _} = Enum.at(clients, (len-2))
        GenServer.call(target_pid, {:subscribe, [n1]})
      end
      if index < (len-1) and index>0 do
        {n1, _} = Enum.at(clients, index+1)
        {n2, _} = Enum.at(clients, index-1)
        GenServer.call(target_pid, {:subscribe, [n1, n2]})
      end
    end)
  end

  defp init(num_client) do
    {:ok,server_pid} = Server.start_link()
    clients = Enum.map(0..(num_client-1), fn x ->
      user_id =Enum.join(["@",Integer.to_string(x)])
      args = [user_id,server_pid]
      {:ok,pid} = Clients.start_link(args)
      {user_id,pid}
    end)
    {server_pid, clients}
  end

  test "query hashtag" do
    # creating clients and assigning subscribers
    {server_pid, clients} = init(10)
    assign_subscribers(clients, server_pid)
    # posting tweet with hashtags by client 2
    {_twitting_user, twitting_pid} = Enum.at(clients,2)
    tweet_msg1 = "This tweet will break the internet. #itIsTrending"
    tweet_msg2 = "Just another tweet. #nobodyCares"
    GenServer.cast(twitting_pid,{:tweet_post, tweet_msg1})
    Process.sleep(1000)
    # client 4 fetches tweetlist with hashtag
    {_querying_user, querying_pid} = Enum.at(clients,4)
    tweet_list = GenServer.call(querying_pid,{:query_hashtag, "#itIsTrending"})
  end

  test "test for disconnected feed update" do
    {server_pid, clients} = init(10)
    assign_subscribers(clients, server_pid)
    {target_id, target_pid} = Enum.at(clients,1)
    {subscribedto_id, subscribedto_pid} = Enum.at(clients, 0)
    {not_subscribedto_id, not_subscribedto_pid} = Enum.at(clients, 2)
    msg_of_user_target_is_subscribed_to = "this is a tweet."
    msg_of_user_target_is_not_subscribed_to = "@1 is mentioned in the post"

    #Querry the feed to check for all users
    feed = GenServer.call(target_pid, {:query_news_feed})
    assert feed == []
    #log off the user with user id @2"
    GenServer.call(target_pid, {:log_off})

    #make a tweet by an user that the user @2 is subscribed to"
    GenServer.cast(subscribedto_pid,{:tweet_post,
                                      msg_of_user_target_is_subscribed_to})

    Process.sleep(500)
    feed = GenServer.call(target_pid, {:query_news_feed})
    [{_,[tweet_from_feed]}] = feed
    assert (tweet_from_feed == msg_of_user_target_is_subscribed_to)
  end

  # test "zipf distribution" do
  #   {server_pid, clients} = init(100)
  #   assign_subscribers_zipf(clients, server_pid)
  # end



  test "test for subscribers" do
    {server_pid, clients} = init(10)
    assign_subscribers(clients, server_pid)
    {target_user, target_pid} = Enum.at(clients,2)
    {n1,_} = Enum.at(clients,1)
    {n2,_} = Enum.at(clients,3)
    ss = GenServer.call(target_pid, {:get_my_followers})
    assert ss == [n2,n1] or ss == [n1,n2]
  end

  test "test for followers" do
    {server_pid, clients} = init(10)
    assign_subscribers(clients, server_pid)
    {target_user, target_pid} = Enum.at(clients,2)
    {n1,_} = Enum.at(clients,1)
    {n2,_} = Enum.at(clients,3)
    ss = GenServer.call(target_pid, {:get_my_subscribeto})
    assert ss == [n2,n1] or ss == [n1,n2]
  end

  test "test to check if user is logged in and logged off successfully" do
    {server_pid, clients} = init(10)
    assign_subscribers(clients, server_pid)
    {target_user, target_pid} = Enum.at(clients,2)

    #check if by default user is logged in.
    {_, user_state_as_per_server} = GenServer.call(server_pid,{:get_user_status,target_user})
    assert user_state_as_per_server == 1

    #check if user is looged off successfully
    GenServer.call(target_pid,{:log_off})
    {_,user_state_as_per_server} = GenServer.call(server_pid,{:get_user_status, target_user})
    assert user_state_as_per_server == 0

    #check if user is logged in again
    GenServer.call(target_pid,{:log_in})
    {_,user_state_as_per_server} = GenServer.call(server_pid,{:get_user_status,target_user})
    assert user_state_as_per_server == 1
  end

end
