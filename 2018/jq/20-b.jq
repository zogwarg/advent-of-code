#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

reduce (first(inputs)[1:-1] / "" | .[]) as $c (
  {
    room: [[0,0]],
    stck: [],
    head: [[0,0]],
    tail: [],
    from: {"\([0,0])":[]},
  };
  # Door to N, E, S or W
  if $c | test("[NESW]") then
    reduce range(.room | length) as $i (.;
       # For each current "live" room, update to next room
      [ .room[$i]  + [$c] ] as $from |
      .room[$i][0] = .room[$i][0] + {N: 0, E: 1, S: 0, W:-1}[$c] |
      .room[$i][1] = .room[$i][1] + {N:-1, E: 0, S: 1, W: 0}[$c] |

      # Keep track of each room, and connected previous room
      .from["\(.room[$i])"] += .from["\(.room[$i])"] + $from
    )
  #  Open parenthesis
  elif $c == "(" then
    .stck += [[.head, .tail]] |            # Push stack
    .head  = (.room | unique) | .tail = [] # New group "ends" init
  # Close parenthesis
  elif $c == ")" then
    .room = ( .room + .tail | unique) # Add rooms from all group
    | .stck[-1] as [$head, $tail]     #
    | .stck = .stck[:-1]              # Destack
    | .head = $head | .tail = $tail   #
  # "Or" event
  elif $c == "|" then
    .tail = ( .room + .tail | unique) |   # Tail += all current rooms
    .room = ( .head | unique ) # Re-add head to start directions from
  end
) |

# Get fully connected graph
reduce (
  .from
  | to_entries[]
  | { k: (.key|fromjson), v:.value[] }
) as {$k,$v} (.from;
  # For each taken step, take reverse step
  .["\($v[0:2])"] = (
    .["\($v[0:2])"] + [
      $k + [{N:"S",E:"W",S:"N",W:"E"}[$v[2]]]
    ] | unique
  )
) |

# Debug display of the base graph
def display_base:
  (
    ( [ .[][][0] ] | [min,max]) as [$xmin,$xmax] |
    ( [ .[][][1] ] | [min,max]) as [$ymin,$ymax] |
    reduce (
      to_entries[] |
      [
        (.key|fromjson| .[0] -= $xmin |.[1] -= $ymin),
        {
          E   : "╴", N   : "╷", W   : "╶", S   : "╵",
          EN  : "┐", NW  : "┌", SW  : "└", ES  : "┘",
          ENS : "┤", ENW : "┬", NSW : "├", ESW : "┴",
          EW  : "─", NS  : "│", ENSW: "┼"
        }[(.value|map(.[2])|sort|add)]
      ]
    ) as [[$x,$y], $c] (
      [
          range($ymax - $ymin) as $y |
        [ range($xmax - $xmin) as $x | " " ]
      ];
      .[$y][$x] = $c
    ) | [ .[] | add | debug ]
  ) as $_ | .
;

{
  base: (display_base | .[][] |= .[0:2]),
  s: [[0,0]],
  d: {
    "[0,0]": 0
  }
} |

# Breadth first search
until (isempty(.s[]);
  .s[0] as $s | .s = .s[1:] |
  reduce .base["\($s)"][] as $n (
    .;
    if (.d["\($n)"] | not) then
      .d["\($n)"] = .d["\($s)"] + 1 |
      .s += [$n]
    end
  )
) |

# N rooms at least 1000 away from start
[ .d[] | select( . >= 1000 ) ] | length
