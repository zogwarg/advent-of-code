#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

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
parse(0)

# Sum metadata items
| [ .. | objects | .m | arrays[] ] | add
