#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[inputs / "\t" | map(tonumber) | max - min] | add
