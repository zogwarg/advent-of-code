#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Scanning for all nanobots, assemble !
[ inputs | [ scan("-?\\d+")|tonumber ]]

| to_entries as $bots |

{
  in_range: [  .[] as $B | $bots  |   # Foreach Bot:B:
    map(      .key as $i | .value |   # All other bots
              .[3] as $R
      | [.[0:3],$B[0:3]] | transpose
      | map( .[0] - .[1] | abs )      # Get man_d(B,i)
      | select(add | . <= $B[3] + $R) # Pts in common?
      | $i
    ) # in_range = [{key:bot_idx,value:[other_idxes]}]
  ]   | to_entries
} |

until ( # Get largest group of bots with pts in common
  [ .in_range[].value|length ] | unique | length == 1;
  ( .in_range | min_by(.value|length).key ) as $remove
  | del(.in_range[]          |select(.key == $remove))
  | del(.in_range[].value[]  |select(   . == $remove))
  | debug({$remove}) # Removing the bot with min reach
) |.in_range[0].value as $i # Only keeping the indices

# Max (man_dist(bot_in_group) - range) must the result
|[$bots[$i[]].value | (.[0:3]|map(abs)|add)-.[3] ]|max
