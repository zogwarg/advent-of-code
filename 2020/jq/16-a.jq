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

[ $rules[][1] | .[0:2], .[2:] ] as $ranges |

reduce (
  $other[][] | select(
    any($ranges[] as [$a,$b] | . >= $a and . <= $b; .) | not
  )
) as $i (0;. + $i)
