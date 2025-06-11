#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Get inputs
( inputs / "\n\n" ) as $inputs |

# Get starting state and number of steps
$inputs[0] | capture("state (?<start>[A-Z])") as {$start} |
$inputs[0] | scan("\\d+") | tonumber as $steps |

[ # Parse inputs to rules
  $inputs[1:][] | scan(
    "In state ([A-Z]).+?"
      +"value is ([01]).+?"
        +"value ([01]).+?"
        +"(left|right).+?"
        +"state ([A-Z]).+?"
      +"value is ([01]).+?"
        +"value ([01]).+?"
        +"(left|right).+?"
        +"state ([A-Z])";
    "m"
  ) | {
    (.[0]): {
      (.[1]):[
        (.[2]|tonumber),
        {"left":-1,"right":1}[.[3]],
        .[4]
      ],
      (.[5]):[
        (.[6]|tonumber),
        {"left":-1,"right":1}[.[7]],
        .[8]
      ]
    }
  }
] | add as $rules |

# Run turing machine for for $steps iterations
reduce range($steps) as $i (
  {
    right: [],
    left: [],
    pos: 0,
    state: $start
  }; if $i % 10000 == 0 then debug($i) end |
  if .pos < 0 then
    $rules[.state][.left[-.pos] // 0 | tostring] as [$w,$m,$s] |
    .left[-.pos] = $w | .state = $s | .pos += $m
  else
    $rules[.state][.right[.pos] // 0 | tostring] as [$w,$m,$s] |
    .right[.pos] = $w | .state = $s | .pos += $m
  end
)

# Output checksum
| .right + .left | add
