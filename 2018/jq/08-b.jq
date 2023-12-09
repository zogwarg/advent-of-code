#!/usr/bin/env jq -n -R -f
[ inputs | scan("\\d+") | tonumber ] as $stream | ($stream | length) as $l |

# Parse message tree
def parse($i):
  $stream[$i:$i+2] as [$c, $m] |
  if $c == 0 then
    {m: $stream[$i+2:$i+2+$m],n:($i+2+$m)}
  else
    reduce range($c) as $_ ({c:[],n:($i+2)};
      .c = ( .c + [parse(.n)] ) |
      .n = .c[-1].n
    )
    | .m = $stream[.n:.n+$m]
    | .n += $m
  end
;

# Start at 0
parse(0) |

# Recursively calculate value of nodes
walk(
  if type == "object" then
    if .c[0] then
      .c as $c |
      .m | map($c[.-1] // 0) | add
    else
      .m | add
    end
  else . end
)
