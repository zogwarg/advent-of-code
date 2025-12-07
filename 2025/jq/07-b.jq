#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] | reduce range(length-1) as $i (
  {
    tachions: {
      "\([0,(.[0] | index("S"))])": 1
    },
    schematic: .
  };

  reduce (.tachions|keys[]|fromjson) as [$y,$x] (.;
    .tachions["\([$y,$x])"] as $c | del(.tachions["\([$y,$x])"]) |
    # Split and add crontributions from current tachion to branches #
    if .schematic[$y+1][$x] == "." then
      .tachions["\([$y+1,$x])"] += $c
    elif .schematic[$y+1][$x] == "^" then
      .tachions["\((1,-1) as $d | [($y+1),($x+$d)])"] += $c
    end
  )
) | [ .tachions[] ] | add # Add up all final paths
