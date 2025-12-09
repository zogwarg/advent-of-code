#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [ scan("\\d+") | tonumber ] ]  |
[ combinations(2) | select(first < last)  |
     transpose    | map(first-last|abs+1) | first * last
] | max
