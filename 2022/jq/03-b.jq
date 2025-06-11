#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Take array and produce groups of $n
def group_of($n):
  ( length / $n ) as $l |
  . as $arr |
  range($l) | $arr[.*$n:.*$n+$n]
;

[
  inputs | explode | map(if .>90 then .-96 else .-38 end)
]

# Take groups of 3
| [ group_of(3)
  # Find element in all three
  | [ map(unique)[][] ] | group_by(.) | sort_by(-length) | .[0][0]
] | add # Output sum
