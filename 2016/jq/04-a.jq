#!/usr/bin/env jq -n -R -f
[
  inputs | split("[[\\]]";"") |
  {
    id: (.[0] | match("\\d+").string | tonumber),
    a: (.[0] | [ match("[a-z]"; "g").string ] | group_by(.) | map([ -length, .[0] ] ) | [ sort[:5][][1] ] | add),
    b: .[1]
  } | select(.a == .b).id
] | add
