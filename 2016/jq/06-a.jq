#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs / "" ] | transpose | map(group_by(.) | max_by(length)[0]) | join("")
