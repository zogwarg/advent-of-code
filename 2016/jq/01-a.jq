#!/usr/bin/env jq -n -R -f

# Vectors with turn Right = +1, turn Left = -1
[
  [0,1],
  [1,0],
  [0,-1],
  [-1,0]
] as $vecs |
{
  "R": 1,
  "L": -1,
} as $turn |

# Walk on map, updating pos and current_vector
{ dir: (inputs / ", ") , pos: [0, 0], cur_v: 0 } | until (.dir | length == 0;
  .i = ( .dir[0] | capture("(?<t>[RL])(?<d>[0-9]+)")) |
  .i.d |= tonumber |
  .cur_v = (4 + .cur_v +  $turn[.i.t] ) % 4 |
  .dir |= .[1:] |
  .pos[0] += $vecs[.cur_v][0] * .i.d |
  .pos[1] += $vecs[.cur_v][1] * .i.d
) |

# Get norm of final position
.pos | map(abs) | add
