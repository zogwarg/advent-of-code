#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[
  inputs | scan("mul\\(\\d+,\\d+\\)")
         | [ scan("\\d+") | tonumber ]
         | .[0] * .[1]
]        | add
