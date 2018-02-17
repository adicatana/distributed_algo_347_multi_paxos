# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Leader do

  defp pmax pvals do
    b = {-1, -1}
    proposal = nil # this is bad programming
    for {ballot_num, s, c} <- pvals do
      if b < ballot_num do
        b = ballot_num
        proposal = {s, c}
      end
    end
    proposal
  end

  def next acceptors, replicas, ballot_num, active, proposals do
    receive do
      {:propose, s, c} ->
        if !Enum.find(proposals, fn p -> match?({s ,_}, p) end) do
          proposals = MapSet.put(proposals, {s, c})
          if active do
            spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
          end
        end
      {:adopted, ^ballot_num, pvals} ->
        proposals = MapSet.put(proposals, pmax(pvals))
        for {s, c} <- proposals, do:
          spawn Commander, :start, [self(), acceptors, replicas, {ballot_num, s, c}]
        active = true
      {:preempted, {r, leader}} ->
        if {r, leader} > ballot_num do
          active = false
          ballot_num = {r + 1, self()}
          spawn Scout, :start, [self(), acceptors, ballot_num]
        end
    end

    next acceptors, replicas, ballot_num, active, proposals
  end

  def start config do
    receive do
      {:bind, acceptors, replicas} ->
        spawn Scout, :start, [self(), acceptors, ballot_num]
        next acceptors, replicas, {0, self()}, false, MapSet.new
    end
  end
end
