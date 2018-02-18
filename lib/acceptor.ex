# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Acceptor do

  def start config do
    # define falsity ballot number as (-1, -1)
    next (-1, -1), MapSet.new
  end

  # Acceptor runs in an infinite loop, receiving two 
  # kinds of request messages from leaders
  defp next ballot_num, accepted do
    receive do
      # ⟨p1a,l,b⟩: receive a phase 1a request message 
      # from a leader with identifier l, for a ballot number b, 
      # an acceptor makes the following transition.  
      # Acceptor adopts b iff it exceeds its current
      # ballot number. Then it returns to l a phase1b response 
      # message containing its current ballot number and all 
      # pvalues accepted thus far by the acceptor.
      {:p1a, l, b} ->
        if b > ballot_num do
          ballot_num = b
        end
        send l, {:p1b, self(), ballot_num, accepted}

      # ⟨p2a,l,⟨b,s,c⟩⟩: receive a phase 2a request 
      # message from leader l with pvalue ⟨b,s,c⟩, 
      # If the current ballot number equals b, then 
      # the acceptor accepts ⟨b,s,c⟩. Acceptor 
      # returns to l a phase 2b response message 
      # containing its current ballot number.        
      {:p2a, l, {b, s, c}} ->
        if ballot_num == b do
          accepted = MapSet.put(accepted, {b, s, c})
        else
          send l, {:p2b, self(), ballot_num}
        end
    end
    next ballot_num, accepted
  end
end
