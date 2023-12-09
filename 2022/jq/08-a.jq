#!/usr/bin/env jq -n -R -f

# Get grid
[ inputs / "" | map(tonumber) ]

# Get grid dimensions
| [ (.[0], .) | length ] as [$w, $h] |

# Get horizontally visible tree idx "H"
[
  to_entries[] | . as {key: $n,value: $row}
  # From left
  | {i: 0, v:[], t: -1} | until (.i == $w;
    if $row[.i] > .t then
      .v = .v + [.i + $n * $w] | .t = $row[.i]
    else . end
    | .i += 1
  ) | .v as $left
  # From right
  | {i: ($w - 1), v:[], t: -1} | until (.i < 0;
    if $row[.i] > .t then
      .v = .v + [.i + $n * $w] | .t = $row[.i]
    else . end
    | .i -= 1
  ) | ( .v + $left | unique[] )
] as $H |

# Get vertically visible tree idx "V"
[
  transpose | to_entries[] | . as {key: $n,value: $col}
  # From top
  | {i: 0, v:[], t: -1} | until (.i == $h;
    if $col[.i] > .t then
      .v = .v + [$n + .i * $h] | .t = $col[.i]
    else . end
    | .i += 1
  ) | .v as $top
  # From bottom
  | {i: ($h - 1), v:[], t: -1} | until (.i < 0;
    if $col[.i] > .t then
      .v = .v + [$n + .i * $h] | .t = $col[.i]
    else . end
    | .i -= 1
  ) | ( .v + $top | unique[] )
] as $V |

# Output number of visible trees = Union(H, V)
$H + $V | unique | length
