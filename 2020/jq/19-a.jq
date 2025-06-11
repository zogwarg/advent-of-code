#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n" |

(
  [
    .[0] / "\n" | .[] | [ scan("\\d+|[ab]|\\|") ] |
    {"\(.[0])": .[1:] } # Get dictionary of rules
  ] | add |             # eg "1: 4 | 2" -> {"1":["4","|","2"]}

  until (length == 1;
    first(
      to_entries[] | select(all(.value[]; test("\\d+") | not))
    ) as {key: $k, value: $v} | "(\($v|add))" as $v |
    del(.[$k]) | walk(       # Build regex recursively
      if . == $k then $v end # Remvoing complete rules
    )                        # Until only 1 left ("0")
  ) | .["0"] | "^\(add)$"
) as $re |

# Output the number of messages that match rule "0"
[ .[1] / "\n" | .[] | select(test($re)) ] | length
