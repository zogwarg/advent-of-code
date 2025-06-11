#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | (scan("\\d+")) | tonumber ] | .[0] as $n |
             # Waiting Time # Bus ID
.[1:] | map([.-($n % .),    .       ]) | min_by(.[0])

| .[0] * .[1] # Output Product
