#!/usr/bin/env jq -n -rR -f
[ inputs / "" ] | transpose | map(group_by(.) | min_by(length)[0]) | join("")
