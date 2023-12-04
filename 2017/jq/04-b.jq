#!/usr/bin/env jq -n -R -f
[ inputs / " " | group_by(. / "" | sort | join("")) | map(length) | max | select(.<2) ] | add
