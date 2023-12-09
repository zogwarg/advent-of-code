#!/usr/bin/env jq -n -R -f

# Get grid
[ inputs / "" | map(tonumber) ]

# Get grid dimensions
| [ (.[0], .) | length ] as [$w, $h] |

# For each tree, get number trees visible left and right
[
  to_entries[] as {key: $n,value: $row} |
  $row | [
    to_entries[] | . as {key: $x, value: $tree} |
    .l = (
      {i:($x-1),v: 0} | until (.i < 0 or $row[.i] >= $tree;
        .i -= 1 | .v += 1
      ) | if .i >= 0 then .v + 1 else .v end
    ) |
    .r = (
      {i:($x+1),v: 0} | until (.i >= $w or $row[.i] >= $tree;
        .i += 1 | .v += 1
      ) | if .i < $w then .v + 1 else .v end
    ) | {l,r}
  ][]
] as $H |

# For each tree, get number trees visible top and bottom
[[
  transpose | to_entries[] as {key: $n,value: $col} |
  $col | [
    to_entries[] | . as {key: $y, value: $tree} |
    .t = (
      {i:($y-1),v: 0} | until (.i < 0 or $col[.i] >= $tree;
        .i -= 1 | .v += 1
      ) | if .i >= 0 then .v + 1 else .v end
    ) |
    .b = (
      {i:($y+1),v: 0} | until (.i >= $h or $col[.i] >= $tree;
        .i += 1 | .v += 1
      ) | if .i < $h then .v + 1 else .v end
    ) | {t,b}
  ]
] | transpose[][] ] as $V |

# Zip together $H and $Z and get scenic score for each tree
[$H, $V] | transpose | map(add | .l * .r * .t * .b)

# Output best scenic score
| max
