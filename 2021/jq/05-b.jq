#!/usr/bin/env jq -n -R -f
def is_v: .[0] == .[2];
def is_h: .[1] == .[3];

reduce ( inputs | [ match("\\d+";"g").string | tonumber ]) as $line (
  {p:{}};
  $line as [$x1, $y1, $x2, $y2] |
  (if $x2 >= $x1 then 1 else -1 end ) as $xi |
  (if $y2 >= $y1 then 1 else -1 end ) as $yi |

  # Horizontal and Vertical lines
  if $line | ( is_v or is_h ) then
    .p[[ [range($x1;$x2;$xi), $x2], [range($y1;$y2;$yi), $y2] ] | combinations | join(",") ] += 1
  # Diagonal lines
  else
    .p[[ [range($x1;$x2;$xi), $x2], [range($y1;$y2;$yi), $y2] ] | transpose[] | join(",") ] += 1
  end
)

# Ouput number of overlapped points
| [ .p[] | select(. > 1) ] | length
