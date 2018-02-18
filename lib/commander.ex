# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Commander do

  # Commander sends a ⟨p2a,leader,⟨b,s,c⟩⟩ message to all 
  # acceptors, and waits for responses of the form 
  # ⟨p2b,acceptor,ballot_num⟩.
  # In each such response ballot_num >= b will hold.  
  def start leader, acceptors, replicas, {b, s, c} do
    for a <- acceptors, do: 
      send a, {:p2a, self(), {b, s, c}}
    next leader, acceptors, replicas, {b, s, c}, acceptors
  end

  defp next leader, acceptors, replicas, {b, s, c}, waitfor do
    receive do
      {:p2b, a, ballot_num} ->
        if ballot_num == b do
          waitfor = MapSet.delete waitfor, a
          if 2 * MapSet.size(waitfor) < MapSet.size(acceptors) do
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

end
