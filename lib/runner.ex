defmodule Runner do

  defp getRandom(self_id, children, pid) do
    if(pid == self_id or pid == nil) do
      getRandom(self_id, children, Enum.random())
    end

  end

  # defp assignsubscribers(clients, server_pid) do
  #   len = length(clients)
  #   Enum.each(0..(len-1), fn index ->

  #     {target_id, target_pid} = Enum.at(clients, index)

  #     if index == 1 do

  #     end
  #     cond do
  #       index == 1 -> GenServer.call(server_pid, {:subscribe, [Enum.at(clients, 1),]})
  #     end
  #   end)
  # end

  def run(argv) do
    start_time = System.system_time(:millisecond)
    [num_client, _num_tweets] = argv
    num_client = String.to_integer(num_client)

    {:ok,server_pid} = Server.start_link()
    _children = Enum.map(1..num_client, fn x ->
      user_id =Enum.join(["@",Integer.to_string(x)])
      args = [user_id,server_pid]
      {:ok,pid} = Clients.start_link(args)
      {user_id,pid}
    end)



    IO.puts("Converged in #{(System.system_time(:millisecond) - start_time) / 1000} seconds")
  end
end
