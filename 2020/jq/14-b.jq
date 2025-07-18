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
              | .[0] |= tobits
    ]
  ]
  | debug({mask:.[0]})
  |   .[0] as $mask | .[1][]    | .[1] as $num
  | [ .[0], $mask ] | transpose | map(
        if .[1] == 0 then [.[0]]
      elif .[1] == 1 then [  1 ]
      else [0,1] end
    )
  |       combinations
  | [ (tonum|tostring), $num]
) as [$addr, $num] (.;.[$addr] = $num)

# Output Sum of all memory
| [  .. | numbers  ] | add
