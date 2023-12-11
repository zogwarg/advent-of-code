#!/usr/bin/env jq -n -R -f

# Annihilitate !. pairs, only keep <(.+)> garbage as "*", cleanup  any non "*" gargage
inputs | gsub("!.";"") | gsub("<(?<g>[^>]*)>";"\(.g|gsub(".";"*"))") | gsub("[^*]";"")

# Output "<>" tagged garbage size
| length
