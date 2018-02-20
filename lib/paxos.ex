# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Paxos do

def main do
  config = DAC.get_config
  if config.debug_level >= 2, do: IO.inspect config
  if config.setup == :docker, do: Process.sleep config.docker_delay
  start config
end

defp start config do
  monitor = spawn Monitor, :start, [config]
  for s <- 1 .. config.n_servers do
    node_name = DAC.node_name config.setup, "server", s
    DAC.node_spawn node_name, Server, :start, [config, s, self(), monitor]
  end

  server_components =
    for _ <- 1 .. config.n_servers do
      receive do { :config, r, a, l } -> { r, a, l } end
    end

  { replicas, acceptors, leaders } = DAC.unzip3 server_components

  for replica <- replicas, do: send replica, { :bind, leaders }
  for leader  <- leaders,  do: send leader,  { :bind, acceptors, replicas }

  # Faulty replicas
  if config.replica_failures > 0 do
    for {_, pid} <- Enum.zip(1 .. config.replica_failures, replicas) do
      :timer.kill_after(:timer.seconds(2), pid)
    end
  end

  # Faulty leaders
  if config.leader_failures > 0 do
    for {_, pid} <- Enum.zip(1 .. config.leader_failures, leaders) do
      :timer.kill_after(:timer.seconds(2), pid)
    end
  end

  # Faulty acceptors
  if config.acceptor_failures > 0 do
    for {_, pid} <- Enum.zip(1 .. config.acceptor_failures, acceptors) do
      :timer.kill_after(:timer.seconds(2), pid)
    end     
  end

  for c <- 1 .. config.n_clients do
    node_name = DAC.node_name config.setup, "client", c
    DAC.node_spawn node_name, Client, :start, [config, c, replicas]
  end

end # start

end # Paxos
