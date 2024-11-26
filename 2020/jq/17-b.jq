#!/usr/bin/env jq -n -R -f

[ inputs / "" | to_entries ]

| to_entries | [ # Build sparse representation
  .[] | .key as $y | .value[] | .key as $x
      | select(.value == "#") | {"\([$x,$y,0,0])": { s: "#" }}
] | add |                                   #└Extra dimension

reduce range(6) as $i (.;
  reduce (
    # Active cubes pos
    keys[] | fromjson
    # Getting all neighbours     ┌─────Extra dimension───┐
    | ( [1,0,-1] |  combinations(4) | select(. != [0,0,0,0]) ) as $d
    | [.,$d] | transpose | map(add) | tojson
    # Foreach count += 1          # Update new/exisiting cubes
  ) as $k (.;.[$k].n += 1) |      with_entries( .value as $v |
      if .value.s == "#" and ([.value.n]|inside([2,3])) then .
    elif .value.s != "#" and               $v.n == 3    then .
    else empty end | del(.value.n) | .value.s = "#"
    # Only keep cubes with active state, and clean up values.
  )
) | length # Final count of active cubes
