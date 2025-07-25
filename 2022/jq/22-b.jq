#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs | rtrim / "\n\n"
| ( .[1] | [ scan("\\d+|.") | tonumber? // . ]  )  as $dir
| .[0] / "\n" | map(. / "") | length as $H | (map(length)|max) as $W |

#  Get the square size  #         Define reverse directions          #
( [$H,$W]|max/4 ) as $S | { u: "d", d: "u", r: "l", l: "r" } as $rev |

( #  Gather the and fold the cube patron, tracking directions  #
  [
    . as $b | range(4) as $y |
    [ range(4) as $x | $b[$y * $S][$x*$S] | . and test("[.#]") ]
  ] |
  {
    patron: .,
    search: [[.[0]|index(true),0]],
    cube: {
      "\([.[0]|index(true),0])": {
        "dir": [1,0,0],
        "u": [0, 0, 1],
        "d": [0, 0,-1],
        "r": [0, 1, 0],
        "l": [0,-1, 0],
      }
    }
  } | until(isempty(.search[]);
    .search[0] as [$x,$y] | .search = .search[1:] |
    reduce (
      (
        [$x+1, $y, "r"], [$x-1, $y, "l"],
        [$x, $y+1, "d"], [$x, $y-1, "u"]
      ) as [$X,$Y,$D] |
      select(all($X,$Y; . >= 0 and . < 4)) |
      select(.patron[$Y][$X]) |
      select(.cube["\([$X,$Y])"] | not) | {$X,$Y} +
      {dir: .cube["\([$x,$y])"][$D] } +
      { ($rev[$D]): .cube["\([$x,$y])"].dir } +
      { ($D): .cube["\([$x,$y])"].dir | map(-.) } + (
        if $D == "r" or $D == "l" then
          .cube["\([$x,$y])"] | {u,d}
        else
          .cube["\([$x,$y])"] | {r,l}
        end
      )
    ) as {$X,$Y,$dir,$u,$d,$l,$r} (.;
      .cube["\([$X,$Y])"] = {$dir,$u,$d,$l,$r} |
      .search = .search + [[$X,$Y]]
    )
  )
  | {cube}
  | reduce (.cube | to_entries[]) as {key: $XY, value: {dir: $d}} (.;
      .dir["\($d)"] = $XY
    )
) as $fold |

[   to_entries[] | .key as $y   | .value
  | to_entries[] | select(.value != " ")
  | .key as $x | {"\([$x,$y])": { s: .value } }
] | add |

(
  reduce (keys[]|fromjson) as [$x,$y] (.;
    reduce ("r","l","d","u") as $d (.;
      def jump:  (
        [$x,$y| . / $S | floor] as [$i1,$j1] |
        (
          $fold.dir["\($fold.cube["\([$i1,$j1])"][$d])"] | fromjson
        ) as [$i2, $j2] |
        [
          $fold.cube["\([$i2,$j2])"] | to_entries[] |
          select(.value == $fold.cube["\([$i1,$j1])"].dir ) |
          $rev[.key]
        ] |
        [ [$i1,$j1], [$i2,$j2], .[0] ]
      );
      def face:
        if $d == "r" then ($x + 1) % $S > 0
      elif $d == "l" then $x % $S > 0
      elif $d == "d" then ($y + 1) % $S > 0
      elif $d == "u" then $y % $S > 0
      else "Unexpected!" | halt_error end;
      def update_face:
        if $d == "r" then [$x+1,$y,$d]
      elif $d == "l" then [$x-1,$y,$d]
      elif $d == "d" then [$x,$y+1,$d]
      elif $d == "u" then [$x,$y-1,$d]
      else "Unexpected!" | halt_error end;

      def low($i): $i * $S;
      def high($i): ($i+1) * $S - 1;
      def zip($i;$x): $i * $S + ($x % $S);
      def rzip($i;$x): $i * $S + ($S-1) - ($x % $S);

      if face then .["\([$x,$y])"][$d] = update_face else
        jump as [[$i1,$j1],[$i2,$j2],$d2] |

        .["\([$x,$y])"][$d] = [ ($d+$d2) as $dd |
          (
            if           $d2 == "r"       then low($i2)
          elif           $d2 == "l"       then high($i2)
          elif $dd == "rd" or $dd == "lu" then rzip($i2;$y)
          elif $dd == "du" or $dd == "ud" then rzip($i2;$x)
          elif $dd == "ru" or $dd == "ld" then zip($i2;$y)
          elif $dd == "dd" or $dd == "uu" then zip($i2;$x)
          else "Unexpected!" | halt_error end
          ),
          (
            if           $d2 == "d"       then low($j2)
          elif           $d2 == "u"       then high($j2)
          elif $dd == "rl" or $dd == "lr" then rzip($j2;$y)
          elif $dd == "dr" or $dd == "ul" then rzip($j2;$x)
          elif $dd == "rr" or $dd == "ll" then zip($j2;$y)
          elif $dd == "dl" or $dd == "ur" then zip($j2;$x)
          else "Unexpected!" | halt_error end
          ),
          $d2
        ]
      end
    )
  )
) as $cube | # Building full cube, after this reuse code from part A #

{
  d: { L: "r", R: "l" }, u: { L: "l", R: "r" },
  l: { L: "d", R: "u" }, r: { L: "u", R: "d" }
} as $turn |

reduce $dir[] as $op (
  {
    pos: "\([
      first(range(1e9) as $x| select($cube["\([$x,0])"])|$x), 0
    ])",
    dir: "r"
  };
  if ($op | tonumber? // false) then
    reduce range($op) as $_ (.;
      if $cube["\($cube[.pos][.dir][0:2])"].s != "#" then
        .dir as $dir | .dir = $cube[.pos][$dir][2] |
        .pos = "\($cube[.pos][$dir][0:2])"
      end
    )
  else
    .dir = $turn[.dir][$op]
  end
)

| (.pos|fromjson|reverse|map(.+1)) + [ .dir as $d | "rdlu"|index($d) ]
| 1000 * .[0] + 4 * .[1] + .[2]
