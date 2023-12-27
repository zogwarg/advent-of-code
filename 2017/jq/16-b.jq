#!/usr/bin/env jq -n -rR -f

[ # Get dance moves
  inputs / "," | .[] | [
    .[0:1],
    (.[1:] / "/" | .[] | (if tonumber? // false then tonumber end))
  ]
] as $dance |

def dance:
  reduce (
    $dance[]
  ) as [$m, $a, $b] (. / "";
    # Shift Right
    if $m == "s" then
      .[16-$a:] + .[:16-$a]
    # Swap positions
    elif $m == "x" then
      .[$a] as $x | .[$a] = .[$b] | .[$b] = $x
    # Swap letters
    elif $m == "p" then
       [index($a,$b)] as [$a,$b]  |
      .[$a] as $x | .[$a] = .[$b] | .[$b] = $x
    end
    # Output final string
  ) | add
;


{ # Dancing until position repeats
  cur: "abcdefghijklmnop" | dance,
  all: ["abcdefghijklmnop"]
} | until (.cur == "abcdefghijklmnop"; .all += [.cur] | .cur |= dance)

# Pos after 1 Billion dances
| .all[10e9 % (.all|length)]
