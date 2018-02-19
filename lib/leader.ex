# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Leader do

  def start config do
    receive do
      {:bind, acceptors, replicas} ->
        ballot_num = {0, self()}
        spawn Scout, :start, [self(), acceptors, ballot_num]
        next acceptors, replicas, ballot_num, false, MapSet.new
    end
  end

  defp next acceptors, replicas, ballot_num, active, proposals do
    receive do
      {:propose, s, c} ->
        if !Enum.find(proposals, fn p -> match?({^s ,_}, p) end) do
          proposals = MapSet.put(proposals, {s, c})
          if active do
            spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
          end
        end
        next acceptors, replicas, ballot_num, active, proposals

      {:adopted, ^ballot_num, pvals} ->
        proposals = update(proposals, pmax(pvals))
        for {s, c} <- proposals do
          spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
        end
        active = true
        next acceptors, replicas, ballot_num, active, proposals

      {:preempted, {r, leader}} ->
        if {r, leader} > ballot_num do
          active = false
          ballot_num = {r + 1, self()}
          spawn Scout, :start, [self(), acceptors, ballot_num]
          next acceptors, replicas, ballot_num, active, proposals
        end
    end
  end

  defp update(x, y) do 
    res = MapSet.new(for {s, elem} <- x, !Enum.find(y, fn p -> match?({^s, _}, p) end), do: {s, elem})
    MapSet.union(res, MapSet.new(y))
  end

  defp find_max_ballot(pvals) do 
    List.foldl(MapSet.to_list(pvals), {-1, -1}, fn {ballot_num, _, _}, acc -> if acc > ballot_num do acc else ballot_num end end)
  end

  # Determines fthe {slot, command} corresponding 
  # to the maximum ballot number in pvals
  defp pmax pvals do
    b = find_max_ballot pvals
    MapSet.new(for {ballot_num, s, c} <- pvals, b == ballot_num, do: {s, c})
  end

end
