#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  "#": 1
} as $update |

[
  inputs / ""
] | ( .[0] | length ) as $l | length as $len |

{
  lines: .,
  pos: [0,0],
  trees: 0
} | until (
  .pos[1] >= $len;
  .trees = (.trees + $update[.lines[.pos[1]][.pos[0] % $l]]) |
  .pos[1] += 1 |
  .pos[0] += 3
) |

# Trees
.trees
