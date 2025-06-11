#!/bin/sh
# \
exec jq -n -rcR -f "$0" "$@"

# Define initial state
{
  pos: [0,0],
  drw: {"0,0": "."}
} as $init |

# Update state for rach move
def update($move; $test; $char):
  # Draw for arrays of keys
  # If other line present: "x"
  def draw($p):
    reduce $p[] as $p (.;
      .drw[$p] |= (
        if . == $test then
          "x"
        else
          $char
        end
      )
    )
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
  end
;

# Get one line and update for all moves in line
def get_line($init; $test; $char):
  reduce (input / "," | .[] | {d: .[0:1], l: (.[1:] | tonumber)}) as $move (
    $init;
    update($move; $test; $char)
  )
;

# Get second line, test if "x" with "1"
get_line(
  # Get first line | Reset position to center
  get_line($init; "_"; "1") | .pos = [0,0];
  "1";
  "2"
) |

# Get "x" with smallest distance
[
  .drw | to_entries[] | select(.value == "x" ) | .key | ( . / "," | map(tonumber|abs) | add)
] | min
