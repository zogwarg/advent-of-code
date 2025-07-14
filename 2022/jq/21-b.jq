#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs
  | [ scan("[a-z]+"), scan("[+/*-]"), (scan("-?\\d+")|tonumber) ]
  | {
      key: .[0],
      value: if .[0] == "humn" then
        { v: [1, 0] }
      elif length == 2 then
        { v: [0, .[1]] }
      else
        { a: .[1], b: .[2], op: .[3] }
      end
    }
]

| from_entries as $OPS |

if [ $OPS[] | .a,.b | strings ] | sort != unique then
  "Assumptions that operation tree has no re-use is not met." | halt_error
end |

def compute($node):
  $OPS[$node].v
  // (
    compute($OPS[$node].a) as [$HA,$A] |
    compute($OPS[$node].b) as [$HB,$B] |
      if $OPS[$node].op == "+" then [($HA+$HB),($A+$B)]
    elif $OPS[$node].op == "-" then [($HA-$HB),($A-$B)]
    elif $OPS[$node].op == "*" then [($HA*$B+$HB*$A),($A*$B)]
    elif $OPS[$node].op == "/" then #  └─ HA*HB = 0
        if [$HA,$HB] == 0 then [0, ($A / $B)]
      elif      $HB  == 0 then [($HA/$B), ($A/$B)]
      else "Divide by a * H + b not supported!" | halt_error end
    else "Unexpected op: \($OPS[$node])" | halt_error end

  )
;

$OPS["root"]

| if .op != "+" then
    "Assumption that root only adds is not met!" | halt_error
  end
| [ compute(.a), compute(.b) ]
| sort_by(.[0] == 0) as [[$HA, $A], [$_, $B]]
| ($B - $A) / $HA
