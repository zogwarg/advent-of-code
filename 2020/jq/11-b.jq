#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{ seats: [ inputs / "" ] } | [.seats,.seats[0]|length] as [$H, $W] |

.seats |= ([ # Get sparse list of seats
    to_entries[] | .key as $y | .value
  | to_entries[] | .key as $x | .value
  | . as $s      |  select($s == "L")
  | {key: "\([$x,$y])", value: { pos: [$x,$y], $s }}
]|from_entries)  |

reduce ( # Get first visible seat in each direction, for every seat.
  .seats | keys[] | [fromjson, .]
) as [[$x,$y],$k] (.;
  .seats[$k].sees = [
    first(                              #     UP    #
      range($y-1;-1;-1) as $yy | .seats["\([$x,$yy])"]
      | objects                |        "\([$x,$yy])"
    ),
    first(                              #    DOWN   #
      range($y+1;$H) as $yy    | .seats["\([$x,$yy])"]
      | objects                |        "\([$x,$yy])"
    ),
    first(                              #    LEFT   #
      range($x-1;-1;-1) as $xx | .seats["\([$xx,$y])"]
      | objects                |        "\([$xx,$y])"
    ),
    first(                              #   RIGHT   #
      range($x+1;$W) as $xx    | .seats["\([$xx,$y])"]
      | objects                |        "\([$xx,$y])"
    ),
    first(                              #   RIGHT  -  DOWN   #
      range(1;$W+$H) as $i     | .seats["\([($x+$i),($y+$i)])"]
      | objects                |        "\([($x+$i),($y+$i)])"
    ),
    first(                              #   RIGHT  -   UP    #
      range(1;$W+$H) as $i     | .seats["\([($x+$i),($y-$i)])"]
      | objects                |        "\([($x+$i),($y-$i)])"
    ),
    first(                              #   LEFT  -   DOWN   #
      range(1;$W+$H) as $i     | .seats["\([($x-$i),($y+$i)])"]
      | objects                |        "\([($x-$i),($y+$i)])"
    ),
    first(                              #   LEFT  -   UP   #
      range(1;$W+$H) as $i     | .seats["\([($x-$i),($y-$i)])"]
      | objects                |        "\([($x-$i),($y-$i)])"
    )
  ]
) |

until(.upd == 0; .upd = 0 | .i += 1 | debug({i}) |
  reduce (
      .seats       | . as $sts
    | .[]          | . as {pos: [$x, $y], $s, $sees } | .
    | select($s != ".")
    | [ $sts[$sees[]].s | select(. == "#") ] | length
    | if [$s, .] == ["L", 0]  then ["\([$x,$y])", "#"]
    elif $s == "#" and . >= 5 then ["\([$x,$y])", "L"]
    else empty end
  ) as [$k,$s] (.;        # This is nicely comapact #
    .seats[$k].s = $s |   # compared to first half  #
    .upd += 1             # of the day              #
  )
)

# Total occupied seats after no changes
| [ .seats[].s | scan("#") ]  |  length
