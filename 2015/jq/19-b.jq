#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

# Parse Inputs
inputs / "\n\n" |

( # Get elements substitutions, sorted by "GREED" (length)
  .[0] / "\n" | [ .[] / " => " ] | sort_by(.[1] | - length )
) as $subs |

# Get molecule
(.[1] | rtrimstr("\n")) as $molecule |

def prev($mol):
  foreach $subs[] as [$j, $i] (null; ($i | length) as $l |
    foreach ($mol | indices($i)[] ) as $k(null;
      # Produce stream with every possible
      # Reverse substitution for $mol
      $mol[:$k] + $j + $mol[$k+$l:]
    )
  )
;

first(
  {
    mols: [$molecule],
    seen: [$molecule]
  }
  | # Get first greedy chain that reduces to "e"
  until (.mols == ["e"] ;
    foreach .mols[] as $mol (.pmols = [];
      foreach prev($mol) as $pmol (.;
        if .seen | contains([$pmol]) then
          empty # Prune streams with seen molecules
        else
          .pmols += [$pmol] |
          .seen  += [$pmol]
        end
      )
    ) | .mols = .pmols
      | .depth += 1
      |  debug("\(.depth) \(.mols)")
  )   | .depth
)
