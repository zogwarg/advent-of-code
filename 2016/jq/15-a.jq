#!/usr/bin/env jq -n -R -f

[ inputs | [ scan("\\d+") | tonumber ] ] |

# For the ball to pass through disk N of size S, and time T + N then
# T + N + offset ≡ 0 mod (S)
# T ≡ -N -offset mod (S)
#
# Supposing all the disk sizes are coprime, this can be solved with
# The chinese remainder theorem

map(
  .[1] as $mod | $mod - .[-1] - .[0] | until (. >= 0; . + $mod)
)  as $rems |
map(
  .[1]
) as $mods |

# Chinese remainder theorem functions
def mul_inv($a; $b):
  if $b == 0 then
    1
  else
    {$a, $b, x0: 0, x1: 1} | until (.a <= 1;
      .q = (.a / .b | floor) |
      .r = (.a % .b ) |
      .a = .b | .b = .r |
      .x = ( .x1 - .q * .x0 ) |
      .x1 = .x0 | .x0 = .x
    ) |
    if .x1 < 0 then .x1 + $b else .x1 end
  end
;

def chinese_rem($mods; $rems):
  reduce ([$mods,$rems] | transpose[]) as [$mi, $ri] (
    {
      sum: 0,
      product: (reduce $mods[] as $m (1; . * $m))
    };
    .p = (.product / $mi | floor) |
    .sum += ( $ri * mul_inv(.p;$mi) * .p)
  ) | .sum % .product
;

chinese_rem($mods;$rems)
