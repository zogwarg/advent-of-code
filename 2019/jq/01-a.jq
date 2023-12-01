#!/usr/bin/env jq -n -R -f
[ inputs | tonumber / 3 | floor - 2 ] | add
