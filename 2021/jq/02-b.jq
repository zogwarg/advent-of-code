#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce inputs as $line ({z: 0,x: 0, a: 0};
  ($line / " " | {(.[0][0:1]): (.[1] | tonumber)}) as $m
  | .a as $a
  | .a += ( $m.d // 0 )
  | .a -= ( $m.u // 0 )
  | .x += ( $m.f // 0 )
  | .z += ( $m.f // 0 ) * $a
)

# Output product of final depth and horizontal positions
| .z * .x
