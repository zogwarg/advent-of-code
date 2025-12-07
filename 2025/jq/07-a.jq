#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] | reduce range(length) as $i (
  {
    tachions: {
      "\([0,(.[0] | index("S"))])": true
    },
    schematic: .
  };

  reduce (.tachions|keys[]|fromjson) as [$y,$x] (.;
    del(.tachions["\([$y,$x])"]) |
    if .schematic[$y+1][$x] == "." then
      .tachions["\([$y+1,$x])"] = true
    elif .schematic[$y+1][$x] == "^" then
      .splits += 1 |
      .tachions["\((1,-1) as $d | [($y+1),($x+$d)])"] = true
    end
  )
) | .splits
