#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Parse inputs
{
  nodes: [
    inputs / " " |
    (
      select(.[0] == "value") | {"value": .[1]|tonumber, to_bot: .[-1]|tonumber}
    ),
    (
      select(.[0] != "value") |
        {"from": .[1]|tonumber, ("hi_"+.[-2][0:3]):.[-1]|tonumber},
        {"from": .[1]|tonumber, ("lo_"+.[5][0:3]):.[6]|tonumber}
    )
    # Group by target bot, or output
  ] | group_by (.to_bot // .hi_bot // .lo_bot )
} |

# Get index of bot holding both values
def get_ready_bot:
  [
    .nodes | to_entries[] | select(
      .value[0].value and
      .value[1].value and
      .value[0].to_bot
    )
  ] [0].key?
;

# Until no bots are ready, or ready bot is comparing 17 and 61
until (get_ready_bot as $i | ($i|not) or ([ .nodes[$i][].value ] | sort) == [17,61];
  # Get bot
  get_ready_bot as $i | (.nodes[$i][0].to_bot ) as $bot | ([ .nodes[$i][].value ] | sort) as [$lo, $hi] |

  # Remove bot from list
  del(.nodes[$i]) |

  # Update other bots, with "values"
  (.nodes[][] | select(.from == $bot and .hi_bot ) ) |=  {value: $hi, to_bot:.hi_bot } |
  (.nodes[][] | select(.from == $bot and .lo_bot ) ) |=  {value: $lo, to_bot:.lo_bot } |

  # Or update outputsm with "values"
  (.nodes[][] | select(.from == $bot and .hi_out ) ) |=  {value: $hi, out:.hi_out } |
  (.nodes[][] | select(.from == $bot and .lo_out ) ) |=  {value: $lo, out:.lo_out }
) |

# Output bot number
.nodes[get_ready_bot][0].to_bot
