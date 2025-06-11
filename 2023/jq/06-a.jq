#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ input | scan("\\d+") | tonumber ] as $times |
[ input | scan("\\d+") | tonumber ] as $dists |

reduce ([ $times, $dists] | transpose[]) as [$t, $d] (1;
  . = . * ([ range($t+1) | . * ( $t - . ) | select(. > $d) ] | length )
)
