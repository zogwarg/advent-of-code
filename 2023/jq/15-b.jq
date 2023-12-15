#!/usr/bin/env jq -n -R -f

# Hash function
def hash: reduce (. | explode[]) as $char (0;
  . + $char | . * 17 | . % 256
);

# Reduce inputs as:
reduce (
  inputs / "," | .[] | [
    scan("[a-z]+"),                        # $c   = step
    scan("-|="),                           # $op  = remove or add/replace
    (scan("\\d+") | tonumber)              # $num = lens focal length
  ] | [ .[0] | hash ] + .                  # $h   = hash of step (box num)
) as [$h, $c, $op, $num] ([range(256)|[]]; # Init = List of empty boxes

  if $op == "-" then
    del( .[$h][] | select(.[0] == $c) )           # Delete  lens in box if found
  elif [ .[$h][][0] == $c ] | any then            #
    ( .[$h][] | select(.[0] == $c) ) = [$c, $num] # Replace lens in box if found
  else                                            #
    .[$h] += [[$c, $num]]                         # Append lens to box otherwise
  end
) |

[
  to_entries[]                       # Foreach box
    | ( .key + 1 ) as $box           # Get box multiplication number
    | .value                         #
    | to_entries[]                   # For each lens in box
      | $box * (.key +1) * .value[1] # Compute lens focusing power
  #----------------------------------- Output total focusing power
] | add
