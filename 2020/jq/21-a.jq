#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def cross: if length >= 2 then .[0] - ( .[0] - (.[1:]|cross) )
         elif length == 1 then .[0] end;
def union: add | unique;

[ inputs / "(contains" | map([scan("\\w+")]) ] as $labels |

(
 $labels | map(.[0]) | add
) - (
  [ $labels[] | .[1][] as $A | [$A, .[0]] ]
  | group_by(.[0])
  | map( [.[0][0], (map(.[1])|cross) ])
  | map(.[1]) | union
)

| length # How many time safe ingredients appear
