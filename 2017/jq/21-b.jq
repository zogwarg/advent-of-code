#!/usr/bin/env jq -n -R -f

[
  # Parse rules, with rotations and reflections
  inputs / " => " | map(. / "/" | map(. / "")) |
  .[1] as $to | .[0] | (
    (.),                             # AB/CD
    (transpose),                     # AC/BD
    (reverse),                       # CD/AB
    (transpose|reverse),             # BD/AC
    (map(reverse)),                  # BA/DC
    (transpose|map(reverse)),        # CA/DB
    (reverse|map(reverse)),          # DC/BA
    (transpose|reverse|map(reverse)) # DB/AC
    | {(add|add): $to}
  )
] | add as $rules |

# Apply 18 iterations
reduce range(18) as $_ (
  [
    [".","#","."],
    [".",".","#"],
    ["#","#","#"]
  ];
  def group_of($n): . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ];
  if length % 2 == 0 then
    map(group_of(2))
    | transpose | map(group_of(2))
    | transpose | map(map($rules[add|add])|transpose|map(add)) | add
  else
    map(group_of(3))
    | transpose | map(group_of(3))
    | transpose | map(map($rules[add|add])|transpose|map(add)) | add
  end | debug($_)
)

# Ouput number of lit pixels
| add | indices("#") | length
