#!/usr/bin/env jq -n -rR -f
[inputs / "\t" | map(tonumber) | max - min] | add
