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
    {:ok,%{}}
  end

  def handle_call({:register_user, pid, user_id},from,state) do
    register_user(pid,user_id)
    {:reply,from,state}
  end

  def handle_call({:delete_user, user_id},from,state) do
    delete_user(user_id)
    {:reply,from,state}
  end

  def handle_call({:subscribe_to_user, target_user_id, source_user_id}) do
    if (isUserValid(target_user_id) == true and isUserValid(source_user_id) == true) do
      ## add the source user as a subscriber to target
      [{_, existing_subscription }] = :ets.lookup(:subscription, target_user_id)
      existing_subscription = [source_user_id | existing_subscription]
      :ets.insert(:subscription,{source_user_id, existing_subscription})

      ## add the target as a user whom the source is following.
      [{_, existing_users_following }] = :ets.lookup(:following, source_user_id)
      existing_users_following = [target_user_id | existing_users_following]
      :ets.insert(:subscription,{source_user_id, existing_users_following})


    end
  end

  defp register_user(pid,user_id) do
    :ets.insert(:users, {user_id, pid})
    :ets.insert(:following, {user_id, []})
    :ets.insert(:subscription, {user_id, []})
    :ets.insert(:tweets, {user_id, []})
  end

  defp delete_user(user_id) do
    :ets.insert(:users,{user_id,-1})
  end

  defp isUserValid(user_id) do
    resp =3
    if ( :ets.lookup(:users, user_id) == [] && :ets.lookup(:following, user_id) == [] and :ets.lookup(:tweets, user_id) == [] and :ets.lookup(:subscription, user_id) == []) do
        false
    else
        true
    end
    resp
  end

end
