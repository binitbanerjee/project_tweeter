defmodule Runner do
  def run(argv) do
    start_time = System.system_time(:millisecond)
    [num_client, _num_tweets] = argv
    num_client = String.to_integer(num_client)

    {:ok,server_id} = Server.start_link()
    _children = Enum.map(1..num_client, fn x ->
      user_id =Enum.join(["@",Integer.to_string(x)])
      args = [user_id,server_id]
      {:ok,pid} = Clients.start_link(args)
      {user_id,pid}
    end)
    IO.puts("Converged in #{(System.system_time(:millisecond) - start_time) / 1000} seconds")
  end
end
