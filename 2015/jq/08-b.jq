#!/usr/bin/env jq -n -R -f

# All inputs: escapedLength - length   | sum
[ inputs | (@json | length) - length ] | add
