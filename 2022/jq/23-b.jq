#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / "" | to_entries
              | map({i: .key, value } | select(.value == "#"))
] | [
  to_entries[] | .key as $j | .value[] | { "\([.i,$j])": .value }
] | add |

{ none: false, board: ., look: [
  [[ 0,-1],[ 1,-1],[-1,-1]], # N, NE, NW
  [[ 0, 1],[ 1, 1],[-1, 1]], # S, SE, SW
  [[-1, 0],[-1,-1],[-1, 1]], # W, NW, SW
  [[ 1, 0],[ 1,-1],[ 1, 1]]  # E, NE, SE
]} |

last(label $out | foreach range(1e9) as $_ (.; debug({$_}) |
  if .none == true then break $out end |
  reduce (.board | keys[] | fromjson) as [$i,$j] (
    {board, look, none: true};
    [
      range(4) as $n | [
        .look[$n][] as [$di,$dj] |
        .board["\([$i+$di,$j+$dj])"] // "."
      ] | select(add == "...") | $n
    ] as [$a,$b,$c,$d] |

    if $a and ($d|not) then
      .look[$a][0] as [$di,$dj] |
      .next["\([$i+$di,$j+$dj])"] += [ "\([$i,$j])" ] |
      .none = false
    else
      .next["\([$i,$j])"] += [ "\([$i,$j])" ]
    end
  ) | reduce (.next | to_entries[]) as {$key, $value} (
    { board: {}, look: .look[1:] + .look[0:1], none };
    if $value | length == 1 then
      .board[$key] = "#"
    else
      reduce $value[] as $key (.; .board[$key] = "#")
    end
  ); $_
)) + 1
