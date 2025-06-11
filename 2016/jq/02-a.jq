#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Generate move map
[
  ( range(1; 3 + 1)             | {(tostring + "U"): tostring}),
  ( range(4; 9 + 1)             | {(tostring + "U"): (. - 3 | tostring)}),
  ( range(1; 6 + 1)             | {(tostring + "D"): (. + 3 | tostring)}),
  ( range(7; 9 + 1)             | {(tostring + "D"): tostring}),
  ( range(0; 3) | . * 3 + 1     | {(tostring + "L"): tostring}),
  ( range(0; 3) | . * 3 + (2,3) | {(tostring + "L"): (. - 1 | tostring)}),
  ( range(0; 3) | . * 3 + 3     | {(tostring + "R"): tostring}),
  ( range(0; 3) | . * 3 + (1,2) | {(tostring + "R"): (. + 1 | tostring)})
] | add as $move |

# Get digits sequence
reduce (inputs / "" ) as $line ({seq: "", cur:"5"};
  .cur = reduce $line[] as $m (.cur; $move[. + $m]) |
  .seq = (.seq + .cur)
) | .seq
