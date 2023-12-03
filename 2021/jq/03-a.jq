#!/usr/bin/env jq -n -R -f

# Get gamma binary string
.gb = ( [ inputs / "" ]  | transpose | [ .[] | group_by(.) | sort_by(-length) | .[0][0] ] | add )

# Get binary string length
| ( .gb | length ) as $n
# Get gamma as int
| .gd = ( .gb | reduce ( . / "" | [[ reverse[] | tonumber ],[range($n)]] | transpose[] ) as [$d,$p] (0; . + $d * pow(2; $p)))
# Get epsilon as 2^n - gamma
| .ed = ( pow(2; $n) - 1 - .gd )
# Output product
| .gd * .ed
