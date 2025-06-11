#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  "#": 1
} as $update |

[
  inputs / ""
] | . as $lines | ( .[0] | length ) as $l | length as $len |

reduce (
  ([1,1], [3,1], [5,1], [7, 1], [1,2]) as [$x,$y] |

  {
    lines: $lines,
    pos: [0,0],
    trees: 0
  } | until (
    .pos[1] >= $len;
    .trees = (.trees + $update[.lines[.pos[1]][.pos[0] % $l]]) |
    .pos[1] += $y |
    .pos[0] += $x
  ) |

  # Trees
  .trees
) as $trees (1; . * $trees)
