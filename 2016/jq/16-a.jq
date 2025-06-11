#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Our dragon curve and checksum functions
def dragon: . + "0" + ( . / "" | reverse | map({"0":"1","1":"0"}[.]) | add );
def check:
  if length % 2 == 1 then . else
    . as $str |
    [
      range(0;length;2) | $str[.:.+2] | {"00":"1","11":"1"}[.] // "0"
    ] | add | check
  end
;

# Expand input to length 272, then perform checksum
inputs | until(length > 272; dragon) | .[:272] | check
