#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs / "x" | map(tonumber) |
  sort |
  (.[0]*.[1]+.[0]*.[2]+.[1]*.[2])*2+(.[0]*.[1])
] | add
