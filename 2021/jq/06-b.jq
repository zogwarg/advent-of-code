#!/usr/bin/env jq -n -R -f
reduce range(256) as $i (
  # Count the number of fish in array [ day 0, day 1, ... ]
  reduce(inputs | scan("\\d+") | tonumber) as $n ([]; .[$n] += 1);
  # Pop fish about to reproduce, and -1 days to all fish with shift
  .[0] as $new | .[1:] |
  # Add old fish to day six, and same number of new fish at day 8
  ( .[6] , .[8] ) += $new
) | add # Count fish
