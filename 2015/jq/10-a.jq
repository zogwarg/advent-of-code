#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Loop 40 iterations
reduce range(40) as $i (inputs; ( $i | debug) as $d |
  [
    # Look-Say consecutive digits is normally 3 at most.
    # Scan/Replace
    scan("111|11|1|222|22|2|33|3") | {
      "111": "31", "11": "21", "1": "11",
      "222": "32", "22": "22", "2": "12",
                   "33": "23", "3": "13"
    }[.]
  ] | add
  # Output length
) | length
