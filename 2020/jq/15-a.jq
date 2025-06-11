#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | scan("\\d+") | tonumber ] |

reduce range(2020-length) as $i (reverse;
  [ .[0] as $n | .[1:] | (index($n)|if . then . + 1 end) // 0 ] + .
) | .[0] # Output the 2020th number said
