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
] | add |

# List parents for each child
reduce to_entries[] as $e ({};
  .[$e.value | keys[]] += [$e.key]
) | . as $to_p |

# Recursively get parents
"shiny gold" | [ recurse($to_p[.][]?) ] | unique

# Ouput count | Remove "shiny gold"
| length      | . - 1
