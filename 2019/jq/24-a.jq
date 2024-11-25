#!/usr/bin/env jq -n -R -f

[
  inputs / ""
] |

def step:
  reduce (
    . as $g
    | to_entries[] | .key as $y | .value
    | to_entries[] | .key as $x | .value as $v
    | [
        $g[$y-1|select(.>=0)][$x],
        $g[$y+1|select(.<=4)][$x],
        $g[$y][$x+1|select(.<=4)],
        $g[$y][$x-1|select(.>=0)] | select(. == "#")
      ]
    | if [$v,length] | . == [".", 1] or . == [".", 2] then [$x,$y,"#"]
    elif [$v,length] | .[0] == "#" and .[1] != 1      then [$x,$y,"."]
    else empty end   #   Only change squares that must be updated
  ) as [$x,$y,$c] (.; .[$y][$x] = $c )
;

def hash: map(add)| add|indices("#") | map(pow(2;.))|add;

{ b: . } | .l[.b|hash] = 1 |          # Since 2^25 is not too large
                                      # We can use an array to check
until ( .i > 500 or .done; .i += 1 |  # Already seen states
  .b = (.b|step) | (.b|hash) as $h |
  if .l[$h] then  .done = true
            else .l[$h] = 1    end
)

| (.b|hash) # Biodiversity rating
