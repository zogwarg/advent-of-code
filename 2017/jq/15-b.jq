#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs | scan("\\d+") | tonumber
] as [$a,$b] |

[ # Sadly quite slow with JQ, although faster than part 1
  foreach range(5000000) as $_ (
    {$a,$b};
    .a = ( .a * 16807 % 2147483647 | until(. % 4 == 0;. * 16807 % 2147483647))|
    .b = ( .b * 48271 % 2147483647 | until(. % 8 == 0;. * 48271 % 2147483647));
    select(.a % 65536 == .b % 65536 ) | debug
  )
] | length
