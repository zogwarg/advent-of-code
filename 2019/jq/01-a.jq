#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | tonumber / 3 | floor - 2 ] | add
