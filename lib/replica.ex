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
        # Decision made by the Synod protocol, command c for slot s
        decisions = MapSet.put(decisions, {s, c})

        {state, slot_in, slot_out, requests, proposals, decisions, leaders, window} = while state, slot_in, slot_out, requests, proposals, decisions, leaders, window

    end
    {state, slot_in, slot_out, requests, proposals, decisions, leaders, window} = propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window

    next state, slot_in, slot_out, requests, proposals, decisions, leaders, window
  end

  defp while state, slot_in, slot_out, requests, proposals, decisions, leaders, window do
    my_list = for {^slot_out, c_prime} <- decisions, do: c_prime

    fst = List.first(my_list)

    if fst != nil do
      my_list_2 = for {^slot_out, c_double} <- proposals, do: c_double
      fst_2 = List.first(my_list_2)
      if fst_2 != nil do
        proposals = MapSet.delete(proposals, {slot_out, fst_2})
        if fst != fst_2 do
          requests = :queue.in(fst_2, requests)
        end
      end

      {state, slot_in, slot_out, requests, proposals, decisions, leaders, window} = perform fst, state, slot_in, slot_out, requests, proposals, decisions, leaders, window
      {state, slot_in, slot_out, requests, proposals, decisions, leaders, window} = while state, slot_in, slot_out, requests, proposals, decisions, leaders, window
    end

    {state, slot_in, slot_out, requests, proposals, decisions, leaders, window}
  end

  def propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window do
    if slot_in < slot_out + window and !:queue.is_empty(requests) do
      if !Enum.find(decisions, fn d -> match?({^slot_in, _}, d) end) do
        {{:value, c}, requests} = :queue.out(requests)
        proposals = MapSet.put(proposals, {slot_in, c})
        for l <- leaders do
          send l, {:propose, slot_in, c}
        end
      end
      slot_in = slot_in + 1
      propose state, slot_in, slot_out, requests, proposals, decisions, leaders, window
    end

    {state, slot_in, slot_out, requests, proposals, decisions, leaders, window}

  end

  defp rec decisions, client, cid, op, slot_out do
    case decisions do
      [{s, {^client, ^cid, ^op}} | t] ->
        a = s < slot_out
        IO.puts "We #{inspect a}"
        s < slot_out or rec t, client, cid, op, slot_out
      [_ | t] -> rec t, client, cid, op, slot_out 
      [] -> false
    end
  end

  def perform {client, cid, op}, state, slot_in, slot_out, requests, proposals, decisions, leaders, window do

    flag = rec(MapSet.to_list(decisions), client, cid, op, slot_out)

    if flag == true do
      slot_out = slot_out + 1
    else
      # {next, result} = op state

      # TODO: send to DATABASE send {op blah blah}
      send state, {:execute, op}
      slot_out = slot_out + 1
      send client, {:reply, cid, :bla}
    end

    {state, slot_in, slot_out, requests, proposals, decisions, leaders, window}

  end

  def isreconfig op do
    match?({_, _, {:reconfig, _}} ,op)
  end


end
