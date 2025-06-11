#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Reverse string
def rev: explode|reverse|implode;

reduce (
  inputs | rtrimstr("\n\n") / "\n\n" | map({
    id: (scan("\\d+")|tonumber),
    edges: (split("\n")[1:] | {
      t: "\(.[0])",
      l: "\([.[][0:1]]|add)",
      r: "\([.[][-1:]]|add)",
      b: "\(.[-1])"
    })
  }) | combinations(2) | select(.[0].id < .[1].id)
     | .[0].id as $a | .[1].id as $b
     | ("t","l","r","b") as $ae
     | ("t","l","r","b") as $be
     | [  .[0].edges[$ae],      .[1].edges[$be] ],
       [ (.[0].edges[$ae]|rev), .[1].edges[$be] ]
     | select(.[0] == .[1])
     | ["\($a)", $ae], ["\($b)", $be]
) as [$id, $e] (.;
  .[$id][$e] += 1 # Count matches for each id/edge
)

# Corners have only 2 matching edges, get Π
| with_entries(select(.value|keys|length==2))
| reduce (keys[]|tonumber) as $i (1; . * $i)
