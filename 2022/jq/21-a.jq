#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
  | [ scan("[a-z]+"), scan("[+/*-]"), (scan("-?\\d+")|tonumber) ]
  | {
      key: .[0],
      value: if length == 2 then
        { v: .[1] }
      else
        { a: .[1], b: .[2], op: .[3] }
      end
    }
]

| from_entries as $OPS |

def compute($node):
  $OPS[$node].v
  // (
    compute($OPS[$node].a) as $A | compute($OPS[$node].b) as $B |
      if $OPS[$node].op == "+" then $A + $B
    elif $OPS[$node].op == "-" then $A - $B
    elif $OPS[$node].op == "*" then $A * $B
    elif $OPS[$node].op == "/" then $A / $B
    else "Unexpected op: \($OPS[$node])" | halt_error end
  )
;

compute("root")
