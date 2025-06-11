#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Get padded grid
[ inputs / "" | ["."] + . + ["."] ] |
[ .+[0,0],.[0]| length ] as [$H,$W] |
[[ range($W) | "." ]] + . +
[[ range($W) | "." ]] |

reduce range(10) as $s (.;
  reduce (
    range(1;$H-1) as $i | range(1;$W-1) as $j |
    {
      $i,$j,
      s: .[$i][$j],
      m: (
        [.[range($i-1;$i+2)][range($j-1;$j+2)]]|del(.[4])|sort|add
      )
    }
    | .s = (
        if .s == "." and .m[-3:]           == "|||" then "|"
      elif .s == "|" and .m[0:3]           == "###" then "#"
      elif .s == "#" and .m[0:1] + .m[-1:] == "#|"  then "#"
      elif .s == "#"                                then "."
      else .s end
    )
    | del(.m)
  ) as {$i,$j,$s} (.;
    .[$i][$j] = $s
  )
) |

# Display
# .[1:-1][] | add[1:-1]

# Accumulate and output product of yards and trees
reduce .[][] as $s ({}; .[$s] += 1) | .["#"] * .["|"]
