#!/usr/bin/env jq -n -R -f

[
  inputs / " contain " | {
    # Holding bag
    (.[0] | scan("^\\w+ \\w+")): ((
                                  # N     held    bag
      .[1] / "," | [ .[] |  scan("(\\d+) (\\w+) (\\w+)") | .[0] |= tonumber | {
        # Held bag item  : Number Held
        (.[1:]|join(" ")): .[0]
      }] | add
    ) // {})
  }
] | add as $map |

[
  # Recursivly get contained bag,
  ["shiny gold", 1] | recurse(
    .[1] as $n | $map[.[0]] | to_entries[] |
    [
      .key,       # Contained Bag name
      $n * .value # Number of contained bags X Number of containing bags
    ]
  )
]

# Sum all bags   | Remove "shiny gold"
| [.. | numbers] | add - 1
