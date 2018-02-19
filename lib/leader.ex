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
      {:adopted, ^ballot_num, pvals} ->
        proposals = update(proposals, pmax(pvals))
        for {s, c} <- proposals do
          spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
        end
        active = true
      {:preempted, {r, leader}} ->
        if {r, leader} > ballot_num do
          active = false
          ballot_num = {r + 1, self()}
          spawn Scout, :start, [self(), acceptors, ballot_num]
        end
    after
      5000 -> IO.puts "muie"
    end

    next acceptors, replicas, ballot_num, active, proposals
  end

  defp update(x, y) do 
    res = MapSet.new
    res = MapSet.union(res, y)
    for {s, elem} <- x do
      if !Enum.find(y, fn p -> match?({^s, _}, p) end) do
        MapSet.put(res, {s, elem})
      end
    end
    res
  end

  defp find_max_ballot(pvals) do 
    b = {-1, -1}
    for {ballot_num, _, _} <- pvals do
      if ballot_num > b do
        b = ballot_num
      end
    end    
    b
  end

  # determines fthe {slot, command} corresponding to the 
  # maximum ballot number in pvals
  defp pmax pvals do
    b = find_max_ballot pvals
    # this is bad programming
    proposals = MapSet.new 
    for {ballot_num, s, c} <- pvals do
      if b == ballot_num do
        proposals.put({s, c})
      end
    end

    proposals
  end

end
