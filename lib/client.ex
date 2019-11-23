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
end
