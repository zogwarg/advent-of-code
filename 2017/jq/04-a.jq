#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " " | group_by(.) | map(length) | max | select(.<2) ] | add
