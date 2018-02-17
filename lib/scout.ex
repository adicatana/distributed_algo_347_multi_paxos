# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Scout do

  def next leader, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, a, ballot_num, accepted_pvalues} ->
        if b == ballot_num do
          pvalues = MapSet.union(pvalues, accepted_pvalues)
          waitfor = MapSet.delete(waitfor, a)
          if MapSet.size(waitfor) * 2 < MapSet.size(acceptors) do
            send leader, {:adopted, b, pvalues}
            exit(:normal)
          end
        else
          send leader, {:preempted, ballot_num}
          exit(:normal)
        end
    end
  end

  def start leader, acceptors, b do
    for a <- acceptors, do:
      send a, {:p1a, self(), b}
    next leader, acceptors, b, acceptors, MapSet.new
  end
end
