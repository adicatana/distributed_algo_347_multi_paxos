# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Leader do

  def start config do
    receive do
      {:bind, acceptors, replicas} ->
        ballot_num = {0, self()}
        spawn Scout, :start, [self(), acceptors, ballot_num]
        next acceptors, replicas, ballot_num, false, MapSet.new, config
    end
  end

  # Main loop of Leader
  defp next acceptors, replicas, ballot_num, active, proposals, config do
    receive do
      {:propose, s, c} ->
        if !Enum.find(proposals, fn p -> match?({^s ,_}, p) end) do
          proposals = MapSet.put(proposals, {s, c})
          if active do
            spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
          end
        end
        next acceptors, replicas, ballot_num, active, proposals, config

      {:adopted, ^ballot_num, pvals} ->
        proposals = update(proposals, pmax pvals)
        for {s, c} <- proposals do
          spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
        end
        active = true
        next acceptors, replicas, ballot_num, active, proposals, config

      {:preempted, {r, leader}} ->
        if config.debug_level == 1 do
          IO.puts "DEBUG ACTIVE: Ping-pong -- ballot number: #{inspect ballot_num}, pid: #{inspect self()}"
        end
        if {r, leader} > ballot_num do
          active = false
          ballot_num = {r + 1, self()}
          # Ping Pong if you spawn the scout immediately
          # Thus, introduce a bit of asymmetry to resolve the livelock
          # Process.sleep(:rand.uniform(1000))
          spawn Scout, :start, [self(), acceptors, ballot_num]
        end
        monitoring_leader = leader
        next acceptors, replicas, ballot_num, active, proposals, config
    end
  end

  defp pmax pvals do
    MapSet.new(for {b, s, c} <- pvals, Enum.all?(pvals, fn {b_prime, s_prime, _} -> s != s_prime or b_prime <= b end), do: {b, s, c})
  end

  # The update function applies to two sets of proposals.
  # Returns the elements of y as well as the elements
  # of x that are not in y.
  # Warning: this is not union! When talking about
  # elements of y, we refer to fst p, where p is a
  # pair in y
  defp update(x, y) do
    res = MapSet.new(for {s, elem} <- x, !Enum.find(y, fn p -> match?({^s, _}, p) end), do: {s, elem})
    MapSet.union(res, MapSet.new(y))
  end

end
