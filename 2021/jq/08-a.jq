#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / " | " | .[1] | scan("\\w+") | select([length]|inside([2,3,4,7])) ] | length
