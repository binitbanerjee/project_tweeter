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
    [num_client, _num_tweets] = argv
    num_client = String.to_integer(num_client)

    {:ok,server_id} = Server.start_link()
    children = Enum.map(1..num_client, fn x ->
      user_id =Enum.join(["@",Integer.to_string(x)])
      args = [user_id,server_id]
      {:ok,pid} = Clients.start_link(args)
      {user_id,pid}
    end)

    client_ids = Enum.map(children, fn {x,_}->
      x
    end)

    tweet(elem(Enum.at(children, 0),0),elem(Enum.at(children, 0),1),1,1,children)
    Process.sleep(2000)


    IO.puts("Converged in #{(System.system_time(:millisecond) - start_time) / 1000} seconds")
  end

  def get_hashtag do
    hashtags = ["#itIsTrending", "#yayElixir", "#whatsInaHashTag"]
    Enum.random(hashtags)
  end

  def tweet(username,user_pid,use_hashtag,use_user_tag, children) do
    tweet_msg = "This is a tweet post."
    hashtag =
    if use_hashtag == 1 do
      get_hashtag()
    else
      ""
    end
    user_tag =
    if use_user_tag == 1 do
      get_user(children, username)
    else
      ""
    end
    tweet_msg = tweet_msg <> " " <> hashtag <> " " <> user_tag
    GenServer.cast(user_pid,{:tweet_post, tweet_msg, hashtag, user_tag})
  end

  defp get_user(children, self_username) do
    child = Enum.random(children)
    user = elem(child, 0)
    user =
    if user == self_username do
      get_user(children, self_username)
    else
      user
    end
  end

end
