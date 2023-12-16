#!/usr/bin/env jq -n -rR -f

# Get inputs, mapped to [0,25], little-end
inputs | explode | map(. - 97) | reverse |

def next:
  until (
    # Three consecutive letters
    any(
      range(0;length-3) as $i | .[$i:$i+3];
      .[0] == .[2] + 2 and .[1] == .[2] + 1
    )
    and
    # Two non overlapping double letters
    any(
      range(0;length-4) as $i | range($i+2;length-2) as $j |
      [ .[$i:$i+2][], .[$j:$j+2][] ];
      .[0] == .[1] and .[2] == .[3] and .[0] != .[2]
    )
    ; # Increase string to next item
      # Starting with increase by 1
      .[0] += 1 | reduce .[] as $i ({d:[],c:0};
      # Include carry
      ( $i + .c ) as $i |

      # Does the next digit have a carry
      .c = (if $i >= 26 then 1 else 0 end) |

      ( # Setting current letter, resetting to "a" if > "z"
        if $i >= 26 then 0
        # Skipping i          o           l
        elif $i == 8 or $i == 14 or $i == 11 then ( $i + 1 )
        else $i end
      ) as $i | .d += [$i]
    ) | .d # New letter "digits"
  )
;

next | .[0] += 1 | next

# Revert to string representation
| reverse | map(. + 97) | implode
