#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Our dragon curve and checksum functions
def dragon: . + "0" + ( . / "" | reverse | map({"0":"1","1":"0"}[.]) | add );

# Each final digit is the parity of ones, within a given chunk
# Were chunk size = highest 2 ^ n divisor
def check:
  length as $n |
  ( 2 | until ($n % . != 0 ; . * 2) / 2 ) as $chunk_size |
  . as $in | [
    range(0;$n;$chunk_size)
    | $in[debug:.+$chunk_size]
    | reduce ( . / "0" | .[] ) as $d (0;. + ($d|length))
    | 1 - ( . % 2 )
    | tostring
  ] | add
;

# Output checksum for large dragon expansion of string.
inputs | until(length | debug > 35651584; dragon) | .[:35651584] | check
