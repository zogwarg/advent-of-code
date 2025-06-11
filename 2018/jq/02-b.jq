#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[
  # Get length from first input
  input as $i | ( $i | length ) as $l |

  # Process all inputs
  ( $i, inputs ) | . as $string |

  # Produce stream, with each letter position hidden
  range($l) | $string[0:.] + "_" + $string[.+1:]
] |

# Select matching strings, with "_" un same position
group_by(.)[] | first(select(length > 1) | .[0] | sub("_"; ""))
