#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Annihilitate !. pairs, only keep <(.+)> garbage as "*", cleanup  any non "*" gargage
inputs | gsub("!.";"") | gsub("<(?<g>[^>]*)>";"\(.g|gsub(".";"*"))") | gsub("[^*]";"")

# Output "<>" tagged garbage size
| length
