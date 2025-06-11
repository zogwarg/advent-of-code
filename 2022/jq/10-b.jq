#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Utility function
def group_of($n): . as $in | [range(0;length;$n) | $in[.:(.+$n)]];

# Make display to letter map
(
  [
    # Font map - Some values are assumed
    # A      B        C        D        E
    " ██  ", "███  ", " ██  ", "███  ", "████ ",
    "█  █ ", "█  █ ", "█  █ ", "█  █ ", "█    ",
    "█  █ ", "███  ", "█    ", "█  █ ", "███  ",
    "████ ", "█  █ ", "█    ", "█  █ ", "█    ",
    "█  █ ", "█  █ ", "█  █ ", "█  █ ", "█    ",
    "█  █ ", "███  ", " ██  ", "███  ", "████ ",
    # F      G        H        I        J
    "████ ", " ██  ", "█  █ ", " ███ ", "  ██ ",
    "█    ", "█  █ ", "█  █ ", "  █  ", "   █ ",
    "███  ", "█    ", "████ ", "  █  ", "   █ ",
    "█    ", "█ ██ ", "█  █ ", "  █  ", "   █ ",
    "█    ", "█  █ ", "█  █ ", "  █  ", "█  █ ",
    "█    ", " ███ ", "█  █ ", " ███ ", " ██  ",
    # K       L        M       N        O
    "█  █ ", "█    ", " █ █ ", "█   █", " ██  ",
    "█ █  ", "█    ", "█████", "██  █", "█  █ ",
    "██   ", "█    ", "█ █ █", "█ █ █", "█  █ ",
    "█ █  ", "█    ", "█ █ █", "█ █ █", "█  █ ",
    "█ █  ", "█    ", "█   █", "█  ██", "█  █ ",
    "█  █ ", "████ ", "█   █", "█   █", " ██  ",
    # P      Q        R        S        T
    "███  ", " ██  ", "███  ", " ███ ", "█████",
    "█  █ ", "█  █ ", "█  █ ", "█    ", "  █  ",
    "█  █ ", "█  █ ", "█  █ ", "█    ", "  █  ",
    "███  ", "█ ██ ", "███  ", " ██  ", "  █  ",
    "█    ", "█  █ ", "█ █  ", "   █ ", "  █  ",
    "█    ", " ██ █", "█  █ ", "███  ", "  █  ",
    # U      V        W        X        Y
    "█  █ ", "█   █", "█   █", "█   █", "█   █",
    "█  █ ", "█   █", "█   █", " █ █ ", "█   █",
    "█  █ ", "█   █", "█ █ █", "  █  ", " █ █ ",
    "█  █ ", " █ █ ", "█ █ █", " █ █ ", "  █  ",
    "█  █ ", " █ █ ", "█████", "█   █", "  █  ",
    " ██  ", "  █  ", " █ █ ", "█   █", "  █  "
  ] | [
    (
      # Reshape input into proper keys
      [ group_of(5) | transpose[] | group_of(6)[] | add ] |
      [ group_of(5) | transpose[][] ]
    ),
    ( "ABCDEFGHIJKLMNOPQRSTUVWXY" / "")
  ] | transpose | map({(.[0]):.[1]}) | add

  # Add missing Z
  | .[
    [
      "████ ",
      "   █ ",
      "  █  ",
      " █   ",
      "█    ",
      "████ "
    ] | add
  ] = "Z"
) as $to_letter |

reduce (                                   # Add phantom ⬇ noop if "addx" op
  inputs | [ scan("-?\\d+") | tonumber ] | if .[0] then null, . else null end
) as [$add] ([1];    # X register starts at 1
  . + [.[-1] + $add] # Cumultive sum array
) |

# Get display rows
group_of(40) | map(select(length==40)) |
map(
  [[range(1;41)], .]
  | transpose
  | map(if .[0] >= .[1] and .[0] < .[1] + 3 then "█" else " " end)
  | add
) |

# Reshape letters to use $to_letter map, printing display to debug.
map(group_of(5)) | transpose |
map(debug("     ") | [ .[] | debug ] | $to_letter[add] // "_") | add
