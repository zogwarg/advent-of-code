#!/usr/bin/env jq -n -R -f
( "a " | explode ) as [$a,$sp] |

[
  inputs | split("[[\\]]";"") |
  {
    id: (.[0] | match("\\d+").string | tonumber),
    a: (.[0] | [ match("[a-z]"; "g").string ] | group_by(.) | map([ -length, .[0] ] ) | [ sort[:5][][1] ] | add),
    b: .[1],
    m: .[0]
  } | select(.a == .b) | ( .id % 26 ) as $shift | .m |= ( explode | map(
      if . >= $a then $a + ( ( . - $a + $shift ) % 26 ) else $sp end
    ) | implode
  ) | select(.m | select(test("north") and test("pole")))
]

# Output id of north pole storage
| first(.[].id)
