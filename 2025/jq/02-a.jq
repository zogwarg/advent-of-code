#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

def f: (first|tostring|length); def l: (last|tostring|length);

[ inputs / "," | .[] | [ scan("\\d+") | tonumber ] ] as $bounds |

if (any($bounds[][]; . >= 1E10)) then
  "Script assumes no bounds are bigger than 1E10!" | halt_error
end |

[
   $bounds[]
   | {
       factors: [ f, l | select(. % 2 == 0) | . / 2 ] | unique,
       bounds: .
     }
   | debug
   | [
       foreach .factors[] as $f (.;
         .div = [2] |
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
