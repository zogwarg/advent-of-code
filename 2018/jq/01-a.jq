#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce ( inputs | tonumber ) as $i (0; . + $i)
