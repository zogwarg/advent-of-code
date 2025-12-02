#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def f: (first|tostring|length); def l: (last|tostring|length);

[  [], [], [1], [1], [1,2], [1], [1,2,3],
   [1], [1,2,4], [1,3], [1,2,5]
] as $factors | # Factors

[ inputs / "," | .[] | [ scan("\\d+") | tonumber ] ] as $bounds |

if (any($bounds[][]; . >= 1E10)) then
  "Script assumes no bounds are bigger than 1E10!" | halt_error
end |

[
   $bounds[]
   | {
       factors: [ $factors[f,l][] ] | unique,
       bounds: .
     }
   | debug
   | [
       foreach .factors[] as $f (.;
         .div = ( [ .bounds[] | tostring | length / $f ] | unique ) |
         .range = [
           range(0; pow(10;$f)) as $i
           | .div[] as $d
           | ([ limit($d; repeat("\($i)")) ] | add | tonumber) as $n
           | select(
              $n >= .bounds[0] and $n <= .bounds[1] and $n > 10
             )
           | $n
         ]
       ) | .range[]
     ]
  | unique[]
] | add
