#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[   inputs
  | [ scan(".") | tonumber? // {"=": -2, "-": -1}[.] // halt_error ]
  | reverse | [ to_entries[] | .value * pow(5;.key) ] | add # UNSNAFU
] | add |

reduce range(log/(5|log)) as $i ({ n:., c:0, out:"" };# SNAFUfication
  (( .n % pow(5;$i+1) | . / pow(5;$i) | floor ) + .c ) as $d |
  if $d > 2 then .c = 1 | .out = "\([0,0,0,"=","-",0][$d])\(.out)"
            else .c = 0 | .out = "\($d)\(.out)" end
)

# Output #
|  .out
