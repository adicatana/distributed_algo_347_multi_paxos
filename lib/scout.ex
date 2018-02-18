# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Scout do

  def start leader, acceptors, b do
    for a <- acceptors, do:
      send a, {:p1a, self(), b}
    next leader, acceptors, b, acceptors, MapSet.new
  end

  # A scout completes successfully when it has collected 
  # ⟨p1b,acceptor,b,accepted_pvalues⟩ messages from all 
  # acceptors in a majority, and returns an ⟨adopted,b,pvalues⟩ 
  # message to its leader l.
  defp next leader, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, a, ballot_num, accepted_pvalues} ->
        if b == ballot_num do
          pvalues = MapSet.union pvalues, accepted_pvalues
          waitfor = MapSet.delete waitfor, a
          if 2 * MapSet.size(waitfor) < MapSet.size(acceptors) do
            send leader, {:adopted, b, pvalues}
            exit(:normal)
          end
          next leader, acceptors, b, waitfor, pvalues
        else
          send leader, {:preempted, ballot_num}
          exit(:normal)
        end
    end
  end

end
