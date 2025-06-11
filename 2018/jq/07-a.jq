#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs | [scan("\\b[A-Z]\\b")] ] |

# All steps and requirements
{
  steps: ( [ .[][] ] | unique ),
  reqs: (.)
}

# Until no more requirements
| until (.reqs | length == 0;
  # Add next available step to output
  (.steps - [ .reqs[][1] ] | sort[0] ) as $s |
  .steps -= [$s] |
  .out += $s |
  .reqs |= [ .[] | select( .[0] != $s) ]
)

# Output + any remaining steps
| .out + (.steps | join(""))
