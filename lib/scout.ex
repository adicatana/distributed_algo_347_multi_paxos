# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Scout do

  # A scout completes successfully when it has collected 
  # ⟨p1b,acceptor,b,accepted_pvalues⟩ messages from all 
  # acceptors in a majority, and returns an ⟨adopted,b,pvalues⟩ 
  # message to its leader l.
  def start leader, acceptors, b do
    for a <- acceptors, do:
      send a, {:p1a, self(), b}
    next leader, acceptors, b, MapSet.new(acceptors), MapSet.new
  end

  # Main loop for Scout
  # Waitfor was specifically converted to a set
  # for faster removals  
  defp next leader, acceptors, b, waitfor, pvalues do
    receive do
      {:p1b, a, ballot_num, accepted_pvalues} ->
        if b == ballot_num do
          # Apply pmax at this point so we don't store redundant pvalues and 
          # also not have to send over the network values that will be dropped
          # by applying pmax at the leader
          pvalues = pmax MapSet.union(pvalues, accepted_pvalues)
          waitfor = MapSet.delete(waitfor, a)
          if 2 * MapSet.size(waitfor) < length(acceptors) do
            stripped_pvals = for {_, s, c} <- pvalues, do: {s, c}
            send leader, {:adopted, b, stripped_pvals}
            exit(:normal)
          end
          next leader, acceptors, b, waitfor, pvalues
        else
          send leader, {:preempted, ballot_num}
          exit(:normal)
        end
    end
  end

  # Determines fthe {slot, command} corresponding 
  # to the maximum ballot number in pvals
  defp pmax pvals do
    MapSet.new(for {b, s, c} <- pvals, Enum.all?(pvals, fn {b_prime, _, _} -> b_prime <= b end), do: {b, s, c})
  end

end
