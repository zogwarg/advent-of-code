#!/usr/bin/env jq -n -R -f
[ inputs / " " | group_by(.) | map(length) | max | select(.<2) ] | add
