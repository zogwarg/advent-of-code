#!/usr/bin/env jq -n -rR -f
[ inputs / "" ] | transpose | map(group_by(.) | max_by(length)[0]) | join("")
