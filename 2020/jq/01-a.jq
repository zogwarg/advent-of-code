#!/usr/bin/env jq -n -R -f
[ inputs | tonumber ] |
[ . , . ] | first(combinations | select(add == 2020)) | .[0] * .[1]