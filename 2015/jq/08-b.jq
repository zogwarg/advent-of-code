#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# All inputs: escapedLength - length   | sum
[ inputs | (@json | length) - length ] | add
