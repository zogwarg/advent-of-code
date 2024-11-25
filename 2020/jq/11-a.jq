#!/usr/bin/env jq -n -R -f

{ seats: [ inputs / "" ], upd: 1, i: 0 }
| [.seats,.seats[0]|length] as [$H, $W] |

until(.upd == 0; .upd = 0 | .i += 1 | debug({i}) |
  reduce (
      .seats       | . as $sts
    | to_entries[] | .key as $y | .value
    | to_entries[] | .key as $x | .value
    | . as $s      | select($s != ".")
    | [
        range([0,$y-1]|max;[$H,$y+2]|min) as $yy |
        range([0,$x-1]|max;[$W,$x+2]|min) as $xx |
        select($xx != $x or $yy != $y) |
        $sts[$yy][$xx] | select(. == "#")
      ] | length
    | if [$s, .] == ["L", 0]  then [$x, $y, "#"]
    elif $s == "#" and . >= 4 then [$x, $y, "L"]
    else empty end
  ) as [$x,$y,$s] (.;
    .seats[$y][$x] = $s |
    .upd += 1
  )
)

# Total occupied seats after no changes
| [ .seats[][] | scan("#") ]  |  length
