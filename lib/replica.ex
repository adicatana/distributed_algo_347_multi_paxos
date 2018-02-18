# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)

defmodule Replica do

  def start config, database, monitor do
    receive do
      {:bind, leaders} ->
        next database, 1, 1, :queue.new, MapSet.new, MapSet.new, leaders, config.window_size
    end
  end

  def next state, slot_in, slot_out, requests, proposals, decisions, leaders, window do
    receive do
      {:client_request, c} ->
        requests = :queue.in(c, requests)

      {:decision, s, c} -> 
      # decision made by the Synod protocol, command c for slot s
        decisions = MapSet.put(decisions, {s, c})

        # For all the decisions that are ready for execution
        for {^slot_out, command} <- decisions do
          perform(command)
        end
    end
    propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window
  end

  def isreconfig op do
    match?({_, _, {:reconfig, _}} ,op)
  end

  def propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window do
    if slot_in < slot_out + window and !:queue.is_empty(requests) do
      if !Enum.find(decisions, fn d -> match?({^slot_in, _}, d) end) do
        {{:value, c}, requests} = :queue.out(requests)
        proposals = Mapset.unin(proposals, {slot_in, c})
        for l <- leaders do
          send l, {:propose, slot_in, c}
        end
      end
      slot_in = slot_in + 1
      propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window
    end


#    for c <- decisions, slot_in < slot_out + window do
#      slot_id = slot_in - window
#      for {^slot_id, {_, _, op}} <- decisions, isreconfig(op) do
#        leaders = op.leaders
#      end

#      if !Enum.find(decisions, fn d -> match?({^slot_in, _}, d) end) do
#        requests = MapSet.difference(requests, MapSet.put(Mapset.new, c))
#        proposals = MapSet.union(proposals, {slot_in, c})
#        for l <- leaders, do:
#            send l, {:propose, slot_in, c}
#      end
#      slot_in = slot_in + 1
#    end

#    next state, slot_in, slot_out, requests, proposals, decisions, leaders, window
  end

  def perform {client, cid, op}, state, slot_in, slot_out, requests, proposals, decisions, leaders, window do

    flag = 0

    for {s, {client_mock, cid_mock, op_mock}} <- decisions do 
      if s < slot_out and client_mock == client and cid_mock == cid and op_mock == op do
        flag = 1
      end
    end

    if flag == 1 do
      slot_out = slot_out + 1
    else
      {next, result} = op state
      state = next
      slot_out = slot_out + 1
      send client, {:reply, cid, result}
    end

  end

#    for {} do

      # mmmm
#      next state, slot_in, slot_out, requests, proposals, decisions, leaders, window
#      exit(:normal)
#    end


#    next state, slot_in, slot_out, requests, proposals, decisions, leaders, window


#    if  or isreconfig(op) do

#    end
#    next state, slot_in, slot_out, requests, proposals, decisions, leaders, window
#  end

end
