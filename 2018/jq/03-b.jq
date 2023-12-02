#!/usr/bin/env jq -n -R -f

# Create empty fabric
{
  "fabric": [ range(1000) | [ range(1000) | 0] ],
  "x": {},
  "ids": []
} as $init |

reduce (
  # Parse each line to numbers
  inputs | split("[#,x]| @ |: ";"")[1:] | map(tonumber)
) as $line (
  $init;
  # Keep ids
  .ids += [$line[0]] |

  # Find all overallped squares
  (
    [ .fabric
        [$line[1] + range($line[3])]
        [$line[2] + range($line[4])]
      | select(. != 0)
      | tostring
    ] | unique
  ) as $x |

  # Add overlapint ids, (including current id)
  if $x | length > 0 then
    .x[ $x[], ($line[0] | tostring)] = true
  else
    .
  end |

  # Patch fabric
  .fabric
    [$line[1] + range($line[3])]
    [$line[2] + range($line[4])] = $line[0]
)

# Get only patch that isn't overlapping
| .ids - (.x | keys | map(tonumber)) | .[]
