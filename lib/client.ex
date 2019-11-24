defmodule Clients do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    [user_id,server_id] = args
    state = %{
      server_id: server_id,
      id: user_id
    }
    GenServer.call(server_id, {:register_user, self(), user_id})
    {:ok, state}
  end

  def handle_cast({:register, server_id, user_id}, _state) do
    state = %{
      server_id: server_id,
      id: Enum.join(["@", user_id])
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

end
