#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | tonumber ] |
[ . , . ] | first(combinations | select(add == 2020)) | .[0] * .[1]