# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)

defmodule Replica do

  def propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window do

    case
    slot_in < slot_out + window and

    next state, slot_in, slot_out, requests, proposals, decisions, leaders, window
  end

  def perform {client, cid, op},   do

  end

  def start config, database, monitor do
    receive do
      {:bind, leaders} ->
        next database, 1, 1, MapSet.new, MapSet.new, MapSet.new, leaders, config.window_size
    end
  end

  def next state, slot_in, slot_out, requests, proposals, decisions, leaders, window do
    receive do
      {:client_request, c} ->
        requests = MapSet.put(requests, c)
      {:decision, s, c} -> # decision made by the Synod protocol, command c for slot s
        decisions = MapSet.put(decisions, {s, c})
        
        # For all the decisions that are ready for execution
        for {^slot_out, command} <- decisions do

          perform(command)
        end
    end
    propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window
  end
end
