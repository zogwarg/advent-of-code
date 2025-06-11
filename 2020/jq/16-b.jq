#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

def scanInt: scan("\\d+")|tonumber;

inputs / "\n\n" |

[
  (.[0] / "\n" | map([scan("^[^:]+"),          [scanInt] ])),
  (.[1] |                                      [scanInt]   ),
  (.[2] / "\n" | [ .[] | select(test("\\d")) | [scanInt] ] )
] as [$rules, $mine, $other] |

$other | map(
  select([.[]|
    any(
      $rules[] as [$_,[$a,$b,$c,$d]]
      | ( . >= $a and . <= $b ) or (. >= $c and . <= $d) ; .
    )
  ]|all)
) as $other | # Only keep tickets where all values match min one range

($other|transpose|to_entries) as $columns | # Get columns for tickets

$rules|map(                   # Each field is compatible with which
  . as  [$_,[$a,$b,$c,$d]] |  # columns?
  [ $columns[] | select(
    all(.value[]; ( . >= $a and . <= $b ) or (. >= $c and . <= $d))
  ) | .key ]
)|

[
  until (all(.[]|length; . == 1);
    [ .[] | select(length == 1) | .[] ] as $t | # Reduce by columns
    ( .[] | select(length > 1)) -= $t           # fitting only 1 field
  ),
  $rules|map(.[0])
]

# Keeo and output the product of the departure fields
| transpose | map(select(.[1] | test("^departure"))[0]) |
reduce $mine[.[]] as $i (1; . * $i)
