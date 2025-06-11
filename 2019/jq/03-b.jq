#!/bin/sh
# \
exec jq -n -rcR -f "$0" "$@"

# Define initial state
{
  pos: [0,0],
  drw: {"0,0": [".", 0]},
  steps: 0
} as $init |

# Update state for rach move
def update($move; $test; $char; $steps):
  # Draw for arrays of keys
  # If other line present: "x"
  def draw($p):
    reduce $p[] as $p (.i = $steps;
      .i += 1 |
      .i as $i |
      .drw[$p] |= (
        if . then
          if .[0] == $test then
            .[0] = "x" |
            . += [$i]
          else
            .
          end
        else
          [$char, $i]
        end
      )
    ) | del(.i)
  ;

  # Draw according to move instruction
  if $move.d == "R" then
    [ range(1; $move.l + 1) as $i | [ .pos[0] + $i, .pos[1]] | join(",") ] as $p |
    draw($p) |
    .pos[0] += $move.l
  elif $move.d == "L" then
    [ range(1; $move.l + 1) as $i | [ .pos[0] - $i, .pos[1]] | join(",") ] as $p |
    draw($p) |
    .pos[0] -= $move.l
  elif $move.d == "U" then
    [ range(1; $move.l + 1) as $i | [ .pos[0], .pos[1] + $i ] | join(",") ] as $p |
    draw($p) |
    .pos[1] += $move.l
  else # D
    [ range(1; $move.l + 1) as $i | [ .pos[0], .pos[1] - $i ] | join(",") ] as $p |
    draw($p) |
    .pos[1] -= $move.l
  end |

  .steps += $move.l
;

# Get one line and update for all moves in line
def get_line($init; $test; $char):
  reduce (input / "," | .[] | {d: .[0:1], l: (.[1:] | tonumber)}) as $move (
    $init;
    update($move; $test; $char; .steps)
  )
;

# Get second line, test if "x" with "1"
get_line(
  # Get first line | Reset position to center, and steps to 0
  get_line($init; "_"; "1") | .pos = [0,0] | .steps = 0;
  "1";
  "2"
) |

# Get "x" with smallest number of steps, from both wires
[
  .drw | to_entries[] | select(.value[0] == "x" ) | .value[1:] | add
] | min
