#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Hash function
def hash: reduce (. | explode[]) as $char (0;
  . + $char | . * 17 | . % 256
);

# Sum of input hashes
[ inputs / "," | .[] | hash ] | add
