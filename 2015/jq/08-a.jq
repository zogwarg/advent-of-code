#!/usr/bin/env jq -n -R -f

# All inputs: L - ( removeBounding(") | escapeSequenceToOne ) | sum
[ inputs | length - ( .[1:-1] | gsub("\\\\(x..|.)";"+") | length ) ] | add
