#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs | rtrim / "\n\n"
| ( .[1] | [ scan("\\d+|.") | tonumber? // . ] )  as $dir
| .[0] / "\n" | map(. / "") | length as $H | (map(length)|max) as $W |

[   to_entries[] | .key as $y   | .value
  | to_entries[] | select(.value != " ")
  | .key as $x | {"\([$x,$y])": { s: .value } }
] | add |

(
  reduce (keys[]|fromjson) as [$x,$y] (.;
    first(
      range(1;1e9) as $i
      | select(.["\([($x+$i)%$W,$y])"])
      | [($x+$i)%$W,$y]
    ) as [$rx,$ry] |
    first(
      range(1;1e9) as $i
      | select(.["\([$x,(($y+$i)%$H)])"])
      | [$x,(($y+$i)%$H)]
    ) as [$dx,$dy] |
    .["\([$x,$y])"].r = "\([$rx,$ry])" |
    .["\([$rx,$ry])"].l = "\([$x,$y])" |
    .["\([$x,$y])"].d = "\([$dx,$dy])" |
    .["\([$dx,$dy])"].u = "\([$x,$y])"
  )
) as $board |

{
  d: { L: "r", R: "l" }, u: { L: "l", R: "r" },
  l: { L: "d", R: "u" }, r: { L: "u", R: "d" }
} as $turn |

reduce $dir[] as $op (
  {
    pos: "\([
      first(range(1e9) as $x| select($board["\([$x,0])"])|$x), 0
    ])",
    dir: "r"
  };
  if ($op | tonumber? // false) then
    reduce range($op) as $_ (.;
      if $board[$board[.pos][.dir]].s != "#" then
        .pos = $board[.pos][.dir]
      end
    )
  else
    .dir = $turn[.dir][$op]
  end
)

| (.pos|fromjson|reverse|map(.+1)) + [ .dir as $d | "rdlu"|index($d) ]
| 1000 * .[0] + 4 * .[1] + .[2]