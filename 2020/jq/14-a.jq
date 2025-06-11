#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

def tobits:
  { n: ., b: [limit(36; repeat(0))] }
  | until (.n == 0; .b[.n|logb] = 1 | .n = .n - pow(2;.n|logb))
  | .b | reverse
;
def tonum: reverse | indices(1) | map(pow(2;.)) | add;

reduce(
  inputs / "mask = " | .[1:][] / "\n" | .[:-1] | [
    (.[0] / "" | map(tonumber? // .)),
    [
      .[1:][] | [ scan("\\d+") | tonumber ]
              | .[1] |= tobits
    ]
  ]
  | .[0] as $mask | .[1][] | .[0] as $addr | [ .[1] , $mask ]
  | transpose | map( if .[1] != "X" then .[1] else .[0] end )
  | [ $addr, tonum ]
) as [$addr, $num] (.;.[$addr] = $num)

# Output Sum of all memory
| [  .. | numbers  ] | add
