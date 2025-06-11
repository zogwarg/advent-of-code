#!/bin/sh
# \
exec jq -f "$0" "$@"

#JQ really shines here
[ .. | numbers ] | add
