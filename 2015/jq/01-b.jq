#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

{
  "(": 1,
  ")": -1
} as $up |

{ "in": ( inputs / "" ), i: 0, cur: 0} | until (.cur < 0 ;
  .i += 1 |
  .cur += $up[.in[0]] |
  .in |= .[1:]
).i
