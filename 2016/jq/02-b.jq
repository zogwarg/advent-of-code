#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Generate move map
[
  (
    [
      ("123456789ABCD" / ""),
      ("121452349678B" / "")
    ] | transpose[] | {(.[0] + "U"): .[1]}
  ),
  (
    [
      ("123456789ABCD" / ""),
      ("36785ABC9ADCD" / "")
    ] | transpose[] | {(.[0] + "D"): .[1]}
  ),
  (
    [
      ("123456789ABCD" / ""),
      ("122355678AABD" / "")
    ] | transpose[] | {(.[0] + "L"): .[1]}
  ),
  (
    [
      ("123456789ABCD" / ""),
      ("134467899BCCD" / "")
    ] | transpose[] | {(.[0] + "R"): .[1]}
  )
] | add as $move |

# Get "digits" sequence
reduce (inputs / "" ) as $line ({seq: "", cur:"5"};
  .cur = reduce $line[] as $m (.cur; $move[. + $m]) |
  .seq = (.seq + .cur)
) | .seq
