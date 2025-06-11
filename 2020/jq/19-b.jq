#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n" |

( [ .[1] / "\n" | .[] | length ] | max ) as $max |

(
  [
    .[0] / "\n" | .[] | [ scan("\\d+|[ab]|\\|") ] |
    {"\(.[0])": .[1:] } # Get dictionary of rules
  ] | add |             # eg "1: 4 | 2" -> {"1":["4","|","2"]}

  if .["0"] != ["8","11"] then           # Assert rule "0"
    "Unexpected rule 0: \(pick(.["0"]))" | halt_error
  end |

  ( # Get the maximum length of rules 42 and 11
    # Then max loop sizes of rules 8 and 11
    ( .[] | select( . == ["a"] or . == ["b"] ) ) |= [1] |

    def sum($v): $v | # Get the maximum match length for a given rule
        if length == 1                 then  .[0]
      elif length == 2                 then  .[0] + .[1]
      elif length == 3 and .[1] == "|" then [.[0]  ,.[2] ]      | max
      elif length == 5 and .[2] == "|" then [.[0:2],.[3:5]|add] | max
      else "Unexpected sequence: \($v)" | halt_error end
    ;

    until(
      all(.["42","31"][]; type == "number" or . == "|");
      first(
        to_entries[]
        | select(.key | . != "42" and . != "31" )
        | select(all(.value[]; type == "number" or . == "|"))
      ) as {key: $k, value: $v} | sum($v) as $v |
      del(.[$k]) | walk(       # Get maximum lengths recursively
        if . == $k then $v end # Removing first fully computed rule
      )                        # Until we have lengths of 42 and 11
    ) | [ .["42","31"] | sum(.) ]
      | [ ($max / .[0]), ($max / add) ] #  "8" = max_8  *  "42"
  ) as [ $max_8, $max_11 ] |            # "11" = max_11 * ("42"+"31")

  # Substitute rules with unrolled loops at maximum depth.
  .["8"] = [
    "42", (
      range(1;$max_8) as $i | "|", limit($i;repeat("42"))
    )
  ] |

  .["11"] = [
    "42", "31", (
      range(1;$max_11) as $i | "|",
      limit($i;repeat("42")), limit($i;repeat("31"))
    )
  ] |

  until (length == 1;
    first(
      to_entries[] | select(all(.value[]; test("\\d+") | not))
                             # (?:) Non capture group
    ) as {key: $k, value: $v} | "(?:\($v|add))" as $v |
    del(.[$k]) | walk(       # Build regex recursively
      if . == $k then $v end # Remvoing complete rules
    )                        # Until only 1 left ("0")
  ) | .["0"] | "^\(add)$"
) as $re |

# Output the number of messages that match rule "0"
[ .[1] / "\n" | .[] | select(test($re)) ] | length
