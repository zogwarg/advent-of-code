#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " | group_by(. / "" | sort | join("")) | map(length) | max | select(.<2) ] | add
