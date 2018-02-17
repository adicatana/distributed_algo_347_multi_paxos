# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Acceptor do

  def start config do
    # define falsity ballot number as (-1, -1)
    next (-1, -1), MapSet.new
  end

  def next b, accepted do
    receive do
      {:p1a, leader, ballot_num} ->
        if ballot_num > b do
          b = ballot_num
        end
        send leader, {:p1b, self(), b, accepted}
      {:p2a, leader, {ballot_num, s, c}} ->
        if b == ballot_num do
          accepted = MapSet.put(accepted, {b, s, c})
        else
          send leader, {:p2b, self(), b}
        end
    end
    next b, accepted
  end
end
