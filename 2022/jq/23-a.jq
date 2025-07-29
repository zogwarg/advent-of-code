#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / "" | to_entries
              | map({i: .key, value } | select(.value == "#"))
] | [
  to_entries[] | .key as $j | .value[] | { "\([.i,$j])": .value }
] | add |

def draw: debug(
  ( [ keys[] | fromjson[0] ] | [min,max] ) as [$xmin, $xmax] |
  ( [ keys[] | fromjson[1] ] | [min,max] ) as [$ymin, $ymax] |
  (
    range($ymin;$ymax+1) as $j | [
    range($xmin;$xmax+1) as $i |
      .["\([$i,$j])"] // "."
    ] | add
  ), "---------------------------------------------------------------"
);

def count:
  ( [ keys[] | fromjson[0] ] | [min,max] ) as [$xmin, $xmax] |
  ( [ keys[] | fromjson[1] ] | [min,max] ) as [$ymin, $ymax] |
  [
    range($ymin;$ymax+1) as $j | [
    range($xmin;$xmax+1) as $i |
      .["\([$i,$j])"] // "." | select(. == ".")
    ] | add
  ] | add | length
;

{ board: ., look: [
  [[ 0,-1],[ 1,-1],[-1,-1]], # N, NE, NW
  [[ 0, 1],[ 1, 1],[-1, 1]], # S, SE, SW
  [[-1, 0],[-1,-1],[-1, 1]], # W, NW, SW
  [[ 1, 0],[ 1,-1],[ 1, 1]]  # E, NE, SE
]} |

reduce range(10) as $_ (.;
  reduce (.board | keys[] | fromjson) as [$i,$j] (.;
    [
      range(4) as $n | [
        .look[$n][] as [$di,$dj] |
        .board["\([$i+$di,$j+$dj])"] // "."
      ] | select(add == "...") | $n
    ] as [$a,$b,$c,$d] |

    if $a and ($d|not) then
      .look[$a][0] as [$di,$dj] |
      .next["\([$i+$di,$j+$dj])"] += [ "\([$i,$j])" ]
    else
      .next["\([$i,$j])"] += [ "\([$i,$j])" ]
    end
  ) | reduce (.next | to_entries[]) as {$key, $value} (
    { board: {}, look: .look[1:] + .look[0:1] };
    if $value | length == 1 then
      .board[$key] = "#"
    else
      reduce $value[] as $key (.; .board[$key] = "#")
    end
  )
) | .board | count
