#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " -> " | map([scan("\\d+")|tonumber]) ] as $in |

#               Extend ymax by 2                   #
([ $in[][][1]]|[min,(max+2)])         as [$ys,$ym] |
([ $in[][][0]]|[(500-$ym),(500+$ym)]) as [$xs,$xm] |
#   Don't need infinite floor, only a triangle     #

# Source block coordinates #
[500-$xs+1,0] as [$sx,$sy] |

               # Extra floor segment #
reduce ($in[], [[$xs, $ym],[$xm, $ym]]) as $segments (
  [ range(1+$ym) | [range(3+$xm-$xs) | " "]] ;
  reduce (
    [ $segments[0:-1], $segments[1:]] | transpose[]
  ) as [[$ax,$ay],[$bx,$by]] (.;
    reduce (
      range($ax;$bx+copysign(1;$bx-$ax);copysign(1;$bx-$ax)) as $x |
      range($ay;$by+copysign(1;$by-$ay);copysign(1;$by-$ay)) as $y |
         {$x,$y}
    ) as {$x,$y} (.; .[$y][$x-$xs+1] = "#" )
  )
) |

def fall($x;$y):
  [ first(
      range($y+1;$ym+1) as $_y | select(.[$_y][$x] != " ") | [$x,$_y]
    )
  ] as [[$_x,$_y]] |
    if $_x|not                then [., true]           # Edge fall
  elif .[$_y][$_x-1]   == " " then fall($_x-1;$_y-1)   # Fall left
  elif .[$_y][$_x+1]   == " " then fall($_x+1;$_y-1)   # Fall right
  elif .[$_y-1][$_x]   == "o" then [., true]           # Source block
                              else .[$_y-1][$_x] = "o" # Settle
  end
;

last(label $out | foreach range(1;1e9) as $i ([0,.];
  [ $i, (.[1] | fall($sx;$sy)) ]
  | if .[1]|last == true then break $out end
))

# Get number of still grains #
| debug( .[1][] | add ) | .[0]
