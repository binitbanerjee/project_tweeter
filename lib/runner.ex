defmodule Runner do

  # defp getRandom(self_id, children, pid) do
  #   if(pid == self_id or pid == nil) do
  #     getRandom(self_id, children, Enum.random())
  #   end

  # end

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

  def run(argv) do
    start_time = System.system_time(:millisecond)
    [num_client, num_tweets] = argv
    num_client = String.to_integer(num_client)
    num_tweets = String.to_integer(num_tweets)

    {:ok,server_pid} = Server.start_link()
    children = Enum.map(1..num_client, fn x ->
      user_id =Enum.join(["@",Integer.to_string(x)])
      args = [user_id,server_pid]
      {:ok,pid} = Clients.start_link(args)
      {user_id,pid}
    end)

    client_ids = Enum.map(children, fn {x,_}->
      x
    end)

    # Utility.assign_subscribers(children, round(length(children)/10))
    Utility.assign_subscribers_zipf(children)

    Enum.each(1..num_tweets, fn _index->
      Enum.map(children, fn {user_id,user_pid}->
        {tweet_msg} = Utility.get_random_tweet(client_ids,user_id)
        GenServer.cast(user_pid,{:tweet_post, tweet_msg})
      end)
      {random_user_id, random_user_pid} = Enum.random(children)
      spawn(Runner, :simulate_log_off_log_in_for_users, [random_user_id, random_user_pid])
      Process.sleep(1000)
    end)
    IO.puts("Converged in #{(System.system_time(:millisecond) - start_time) / 1000} seconds")
  end

  #This simulates the scenario where the user logs off and then logs in after 500ms.
  def simulate_log_off_log_in_for_users(user_id, user_pid) do
    IO.puts("logging off : #{inspect user_id}")
    GenServer.call(user_pid,{:log_off})
    Process.sleep(200)
    IO.puts("logging back in : #{inspect user_id}")
    GenServer.call(user_pid,{:log_in})
  end

  def get_hashtag do
    hashtags = ["#itIsTrending", "#yayElixir", "#whatsInaHashTag"]
    Enum.random(hashtags)
  end
end
