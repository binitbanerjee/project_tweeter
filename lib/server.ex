defmodule Server do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_args) do
    :ets.new(:users,[:set, :public, :named_table])
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

  defp register_user(pid,user_id) do
    :ets.insert(:users, {user_id, [pid,[],[],[]]})
  end

  defp delete_user(user_id) do
    :ets.insert(:users,{user_id,[-1,[],[],[]]})
  end

end
