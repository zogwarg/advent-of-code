#!/usr/bin/env jq -n -R -f
[
  inputs / ""
  | [ .[0:7], .[7:] ] as [$r, $c]
  | reduce $r[] as $l ([range(128)]; if $l == "F" then .[:length/2] else .[length/2:] end) | . as [$r]
  | reduce $c[] as $l ([range(8)];   if $l == "L" then .[:length/2] else .[length/2:] end) | . as [$c]
  | $r * 8 + $c
]

# Sort seat ids
| sort

# Find gap of 2 between consecutive seats, and return our seat
| .[
 [
   [.[0:-1] ,.[1:]]
   | transpose[]
   | .[1] - .[0]
 ] | index(2)
] + 1
