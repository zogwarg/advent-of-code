#!/usr/bin/env jq -n -R -f
reduce ( inputs | tonumber ) as $i (0; . + $i)
