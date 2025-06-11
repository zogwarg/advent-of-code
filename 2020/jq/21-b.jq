#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

def cross: if length >= 2 then .[0] - ( .[0] - (.[1:]|cross) )
         elif length == 1 then .[0] end;

[ inputs / "(contains" | map([scan("\\w+")]) ] as $labels |

[ $labels[] | .[1][] as $A | [$A, .[0]] ]
| group_by(.[0]) # Also sorts by allergen
| map( [.[0][0], (map(.[1])|cross) ]) |

until (all(.[][1]|length;. == 1);
  [ .[][1] | select(length == 1) | .[] ] as $rem |
  ( .[][1] | select(length >= 2) ) |= ( . - $rem )
) |

map(.[1][0]) | join(",") # By allergen dangerous ingredients.
