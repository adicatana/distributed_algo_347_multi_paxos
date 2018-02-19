# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)

defmodule Replica do

  def start config, database, monitor do
    receive do
      {:bind, leaders} ->
        next database, 1, 1, :queue.new, MapSet.new, MapSet.new, leaders, config, monitor
    end
  end

  def next state, slot_in, slot_out, requests, proposals, decisions, leaders, config, monitor do
    receive do
      {:client_request, c} ->
        requests = :queue.in(c, requests)
        send monitor, { :client_request, config.server_num }
      {:decision, s, c} -> 
        # Decision made by th e Synod protocol, command c for slot s
        decisions = MapSet.put(decisions, {s, c})

        {slot_out, requests, proposals} = while state, slot_in, slot_out, requests, proposals, decisions, leaders, config
    end
    {slot_in, requests, proposals} = propose state, slot_in, slot_out, requests, proposals, decisions, leaders, config

    next state, slot_in, slot_out, requests, proposals, decisions, leaders, config, monitor
  end

  defp while state, slot_in, slot_out, requests, proposals, decisions, leaders, config do

    command_1 = List.first(for {^slot_out, c_prime} <- decisions, do: c_prime)

    if command_1 do
      command_2 = List.first(for {^slot_out, c_double} <- proposals, do: c_double)
      if command_2 do
        proposals = MapSet.delete(proposals, {slot_out, command_2})
        if command_1 != command_2 do
          requests = :queue.in(command_2, requests)
        end
      end

      # Perform
      {client, cid, op} = command_1
      if !check_for_decision(MapSet.to_list(decisions), client, cid, op, slot_out) do
        send state, {:execute, op}      
        send client, {:reply, cid, :result}
      end
      while state, slot_in, slot_out + 1, requests, proposals, decisions, leaders, config
    else
      {slot_out, requests, proposals}
    end
  end

  def propose state, slot_in, slot_out, requests, proposals, decisions, leaders, config do
    if slot_in < slot_out + config.window_size and !:queue.is_empty(requests) do
      if !Enum.find(decisions, fn d -> match?({^slot_in, _}, d) end) do
        {{:value, c}, requests} = :queue.out(requests)
        proposals = MapSet.put(proposals, {slot_in, c})
        for l <- leaders do
          send l, {:propose, slot_in, c}
        end
      end
      propose state, slot_in + 1, slot_out, requests, proposals, decisions, leaders, config
    else
      {slot_in, requests, proposals}
    end
  end

  defp check_for_decision decisions, client, cid, op, slot_out do
    case decisions do
      [{s, {^client, ^cid, ^op}} | t] ->
        s < slot_out or check_for_decision t, client, cid, op, slot_out
      [_ | t] -> check_for_decision t, client, cid, op, slot_out 
      [] -> false
    end
  end

  def isreconfig op do
    match?({_, _, {:reconfig, _}} ,op)
  end


end
