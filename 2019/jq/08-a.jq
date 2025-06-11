#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Utility
def group_of($n):
  . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ]
;

# Take all inputs
inputs / ""
# Group up pixels by layer
| group_of(25 * 6)
# Select layer with fewest pixels == "0"
| min_by([.[] | select(. == "0")] | length)
# Count number of pixels per type
| group_by(.) | map({(.[0]): length}) | add
# Output number of "1" * "2"
| .["1"] * .["2"]
