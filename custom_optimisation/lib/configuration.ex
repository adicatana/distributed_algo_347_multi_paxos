# Panayiotis Panayiotou (pp3414) and Adrian Catana (ac7815)
defmodule Configuration do

def version 1 do	# configuration 1
  %{
  debug_level:  0, 	# debug level
  docker_delay: 5_000,	# time (ms) to wait for containers to start up

  max_requests: 500,   	# max requests each client will make
  client_sleep: 5,	# time (ms) to sleep before sending new request
  client_stop:  10_000,	# time (ms) to stop sending further requests
  n_accounts:   100,	# number of active bank accounts
  max_amount:   1000,	# max amount moved between accounts

  print_after:  1_000,	# print transaction log summary every print_after msecs

  replica_failures: 0, # Number of replica failures
  acceptor_failures: 0, # Number of acceptor failures
  leader_failures: 0, # Number of leader failures
  window_size: 100 # For replicas: Max amount of more commands that are proposed than decided by the Synod protocol
  }
end

def version 2 do	# same as version 1 with higher debug level
 config = version 1
 Map.put config, :debug_level, 1
end

def version 3 do
  config = version 1
  Map.put config, :replica_failures, 5 # Use 6 (f + 1) servers to tolerate
end

def version 4 do
  config = version 1
  Map.put config, :acceptor_failures, 3 # Use 7 (2 * f + 1) servers to tolerate
  # In the current setup each server has 1 acceptor
end

def version 5 do
  config = version 1
  Map.put config, :leader_failures, 5 # Use 6 (f + 1) servers to tolerate
end

def version 6 do # pushing the failure tolerance testing to the boundary
  config = version 1
  # Use 7 servers to tolerate
  # Use 6 servers to observe failure
  Map.put config, :leader_failures, 6 # need 7 servers to tolerate
  Map.put config, :acceptor_failures, 3 # need 7 servers to tolerate
  Map.put config, :replica_failures, 4
end

def version 7 do
  config = version 1
  Map.put config, :acceptor_failures, 4 # Use 8 servers to observe failure
  # In the current setup each server has 1 acceptor
end

end # module -----------------------
