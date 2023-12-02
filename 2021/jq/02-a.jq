#!/usr/bin/env jq -n -R -f
reduce inputs as $line ({z: 0,x: 0};
  ($line / " " | {(.[0][0:1]): (.[1] | tonumber)}) as $m
  | .z += ( $m.d // 0 )
  | .z -= ( $m.u // 0 )
  | .x += ( $m.f // 0 )
)

# Output product of final depth and horizontal positions
| .z * .x
