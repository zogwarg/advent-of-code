#!/usr/bin/env jq -n -R -f

[ inputs | (scan("\\d+")) | tonumber ] | .[0] as $n |
             # Waiting Time # Bus ID
.[1:] | map([.-($n % .),    .       ]) | min_by(.[0])

| .[0] * .[1] # Output Product
