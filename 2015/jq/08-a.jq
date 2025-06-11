#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# All inputs: L - ( removeBounding(") | escapeSequenceToOne ) | sum
[ inputs | length - ( .[1:-1] | gsub("\\\\(x..|.)";"+") | length ) ] | add
