#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# JQ is ill-suited to this task
# TODO: maybe super slow implementation of md5
0
