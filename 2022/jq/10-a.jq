#!/usr/bin/env jq -n -R -f

reduce (                                   # Add phantom ⬇ noop if "addx" op
  inputs | [ scan("-?\\d+") | tonumber ] | if .[0] then null, . else null end
) as [$add] ([1];    # X register starts at 1
  . + [.[-1] + $add] # Cumultive sum array
)

# Get sum of signal strengths at given cycles
| [20, 60, 100, 140, 180, 220] as $nth
| [ $nth[] as $n | .[$n - 1] * $n ] | add
