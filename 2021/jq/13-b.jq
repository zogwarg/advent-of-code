#!/usr/bin/env jq -n -srR -f

inputs / "\n\n"

| .[0] |= ( . / "\n" |  map([scan("\\d+")|tonumber]) )
| .[1] |= [ scan("[xy]=\\d+")/"=" | .[1] |= tonumber ]

| reduce .[1][] as [$f,$v] (.[0];
    def fold($i): map(if .[$i] > $v then .[$i] = 2 * $v - .[$i] end);
                      if  $f == "y" then fold(1)
                     elif $f == "x" then fold(0) end
  )

# Get final Dimensions
| [ map(.[0]), map(.[1]) | max+1 ] as [ $W, $H ] |

# Draw
reduce .[] as [$x,$y] (
  [ range($H) | [ range($W) | " " ] ]; .[$y][$x] = "█"
) | .[] |= debug(add) |

#══════════════════ Make display to letter map ════════════════════#

def group_of($n): . as $in | [ range(0;length;$n) | $in[.:(.+$n)] ];

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
) as $to_letter

#════════════════════════ Final output ════════════════════════════#

          | map(group_of(5)) | map(.[-1] += [" "])
          | transpose        | map($to_letter[add|add] // "_")
          | add