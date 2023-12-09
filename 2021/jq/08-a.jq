#!/usr/bin/env jq -n -R -f
[ inputs / " | " | .[1] | scan("\\w+") | select([length]|inside([2,3,4,7])) ] | length
