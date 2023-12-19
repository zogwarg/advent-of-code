#!/usr/bin/env jq -n -sR -f

# Parse Inputs
inputs / "\n\n" |

( # Get elements substitutions
  .[0] / "\n" | [ .[] / " => " ]
) as $subs |

# Get molecule
.[1] as $molecule |

[ # For each substitution pair
  $subs[] as [$from, $to] | ($from|length) as $l |
  # Get every index position of from
  ( # In the molecule
    $molecule | indices($from)[]
  ) as $id |

  # Subtitute once seperately at each position
  $molecule[0:$id] + $to + $molecule[$id+$l:]

  # Count unique resulting molecules
] | unique | length
