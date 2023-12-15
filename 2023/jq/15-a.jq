#!/usr/bin/env jq -n -R -f

# Hash function
def hash: reduce (. | explode[]) as $char (0;
  . + $char | . * 17 | . % 256
);

# Sum of input hashes
[ inputs / "," | .[] | hash ] | add
