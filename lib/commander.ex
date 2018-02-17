# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Commander do

  def next leader, acceptors, replicas, {b, s, c}, waitfor do
    receive do
      {:p2a, a, ballot_num} ->
        if ballot_num == b do
          waitfor = MapSet.delete(waitfor, a)
          if MapSet.size(waitfor) * 2 < MapSet.size(acceptors) do
            for r <- replicas, do:
              send r, {:decision, s, c}
            exit(:normal)
          end
          next leader, acceptors, replicas, {b, s, c}, waitfor
        else
          send leader, {:preempted, ballot_num}
          exit(:normal)
        end
    end
  end

  def start leader, acceptors, replicas, {b, s, c} do
    for a <- acceptors, do: send a, {:p2a, self(), {b, s, c}}
    next leader, acceptors, replicas, {b, s, c}, acceptors
  end
end
