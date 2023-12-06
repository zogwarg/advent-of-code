#!/usr/bin/env jq -n -R -f

[ input | scan("\\d+") | tonumber ] as $times |
[ input | scan("\\d+") | tonumber ] as $dists |

reduce ([ $times, $dists] | transpose[]) as [$t, $d] (1;
  . = . * ([ range($t+1) | . * ( $t - . ) | select(. > $d) ] | length )
)
