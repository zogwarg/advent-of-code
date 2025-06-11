#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Reverse string - Transpose Tile - Rotate Tile
def rev:     explode  |  reverse  |     implode ;
def   T: map(explode) | transpose | map(implode);
def   R:            T |  reverse                ;

reduce (
  inputs | rtrimstr("\n\n") / "\n\n" | map({
    id:    (scan("\\d+")|tonumber),
    edges: (split("\n")[1:] | {
      t: "\(.[0])",
      l: "\([.[][0:1]]|add)",
      r: "\([.[][-1:]]|add)",
      b: "\(.[-1])"
    }),
    tile: (split("\n")[1:])
  })
  | combinations(2)          | select(.[0].id < .[1].id)
  | map(.id) as [$a, $b]     | map(.tile) as [$ta, $tb]
  | ("t","l","r","b") as $ae | ("t","l","r","b") as $be
  | [  .[0].edges[$ae],      .[1].edges[$be] ],
    [ (.[0].edges[$ae]|rev), .[1].edges[$be] ]
  | select(.[0] == .[1])     #  Select matching edges #
  | ["\($a)", $ae, "\($b)", $be, $ta], # Add info for #
    ["\($b)", $be, "\($a)", $ae, $tb]  # both tiles   #
) as [$a, $ae, $b, $be, $ta] (.; .[$a].id = $a
  | .[$a].tile = $ta         # Save tile              #
  | .[$a][$ae] = [$b, $be]   # Add edge to edge match #
) |

# Get top-left corner
.curr = first(
  .[] | select(length == 4)
      | if .t then .tile |= reverse  | .b = .t | del(.t) end
      | if .l then .tile |= map(rev) | .r = .l | del(.l) end
)     |

# Start board
{ pos: [0,0], curr, b: [[.curr]], g: . } |

# Build board until we reach bottom right corner
until (.curr | all(.t,.l;.) and all(.b,.r; not);
  # Tile Transpose tt, Tile Horizontal Flip th, Tile Vertical File tv
  def tt: { id, t: .l, b: .r, l: .t, r: .b, tile: (.tile|T)        };
  def th: { id, t,     b,     l: .r, r: .l, tile: (.tile|map(rev)) };
  def tv: { id, t: .b, b: .t, l,     r,     tile: (.tile|reverse)  };

  # Rotate next tile, right of current tile
  def R($s;$k;$e;$d): if $d == "b" then $s | tt | th
                    elif $d == "t" then $s | tt
                    elif $d == "r" then $s | th
                    else $s end
                    | if "\([.tile[][0:1]]|add)" != $e then tv end;

  # Rotate next tile, bottom of current tile
  def B($s;$k;$e;$d): if $d == "r" then $s | tt | tv
                    elif $d == "l" then $s | tt
                    elif $d == "b" then $s | tv
                    else $s end
                    |           if "\(.tile[0])" != $e then th end;

  if .curr.r then
    # Go right
    .pos[0] += 1
    # Matching Edge                         # Next tile
    | (.curr|"\([.tile[][-1:]]|add)") as $e | .curr.r as [$k,$d]
    | .curr = R(.g[$k]; $k; $e; $d)         # Rotate
    | .b[.pos[1]][.pos[0]] = .curr          # Update board
  elif .curr.l and .curr.b then
    # Go to start of line, and match towards bottom
    .pos = [ 0, (.pos[1]+1) ]
    | .curr = .b[.pos[1]-1][0]
    # Matching Edge                         # Next tile
    | (.curr|"\(.tile[-1])")          as $e | .curr.b as [$k,$d]
    | .curr = B(.g[$k]; $k; $e; $d)         # Rotate
    | .b[.pos[1]][.pos[0]] = .curr          # Update board
  else
    "Unexpected state." | halt_error
  end
) | .b

#   Merge tiles into one large map    #
| .[][] |= (.tile[1:-1] | map(.[1:-1]))
| .[]   |= (transpose|map(add))
| add   |

[
  "..................#.",  #  Matching RE for  #
  "#....##....##....###",  #       our         #
  ".#..#..#..#..#..#..."   #   Sea Monster     #
] as $mon | [$mon,$mon[0]|length] as [$mH,$mW] |

([   .[]|scan("#")]|length) as $scn_tot | # Total   "#"
([$mon[]|scan("#")]|length) as $mon_tot | # Monster "#"

first(
    (., map(rev))                 #  Get sea map in all 8 possible  #
  | limit(4; recurse(R))          #          orientations           #
  | [., .[0]|length] as [$H,$W] | #                                 #

  [
    range(0;$H-$mH) as $y | range(0;$W-$mW) as $x |
    select(all(
      range($mH) as $i |
      .[$y+$i][$x:$x+$mW] | test($mon[$i]);
      .
    )) | "x" # One location matches the monster
  ]

  # Assuming the sea monsters do not overlap
  # Roughness =  Total "#" - N * Monster "#"
  | select(any) | $scn_tot - length * $mon_tot
)
