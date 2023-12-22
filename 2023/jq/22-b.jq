#!/usr/bin/env jq -n -R -f

{ # Get all starting bricks, sorted by z, so they can be
  # Dropped in order, with proper "top" collision
  bricks: (
    [ inputs | [scan("\\d+") | tonumber] ] | sort_by(.[2])
  )
} |

# Drop a brick until it collides
def drop($b; $top):
 (
   [
     range($b[0]; $b[3] + 1) as $x |
     range($b[1]; $b[4] + 1) as $y |
     $top["\($x),\($y)"] // 0
   ] | max
 ) as $z_collide | $b |
 .[2,5] -= (.[2] - $z_collide - 1 )
;

# Update top z for each x,y
# For latest dropped brick
def update_top($b;$top):
  $b[5] as $z |
  reduce (
    range($b[0]; $b[3] + 1) as $x |
    range($b[1]; $b[4] + 1) as $y |
    "\($x),\($y)"
  ) as $xy ($top; .[$xy] = $z)
;

# Make the bricks fall
def fall:
  reduce .bricks[] as $b (
    {
      top: {},
      bricks: [],
      falls: 0
    };
    drop($b; .top) as $nb
    | .bricks += [$nb]
    | .top = update_top($nb;.top)
    | if $nb[2] < $b[2] then .falls += 1 end
  )
;

# Get bricks after first fall
( fall | .bricks ) as $bricks |

[ # Add up how many bricks fall
  # for each removed brick
  range($bricks|length) as $i |
  { bricks: ($bricks | del(.[$i|debug]) )} | fall
  | .falls
] | add
