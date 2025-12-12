#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Simple heuristic unsatisfyingly works
# TODO: Implementation that proves its work!

inputs | trim / "\n\n" |

( .[0:-1] | map([scan("#")]|length)) as $present_areas |

[
  .[-1] / "\n" | .[] | [ scan("\\d+") | tonumber ] |
  (
    [ .[2:], $present_areas ] | transpose | map(first * last) | add
  ) < .[0] * .[1] | select(.)
] | length
