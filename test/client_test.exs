defmodule ClientTest do

  use ExUnit.Case
  doctest PROJ4

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

end
