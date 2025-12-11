#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#            Parse as S = { "parent": ["children", ...] }           #
[ inputs / ": " | .[1] |= split(" ") | {(.[0]): .[1]} ] | add as $S |

[ [ "you" ] #       Satisfying JQ recursion method            #
  | recurse( ( $S[.[-1]]| arrays[] ) as $n | . + [$n] | debug )
  | select(last == "out")
] | length
