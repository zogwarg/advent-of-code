#!/usr/bin/env jq -n -R -f

reduce ( inputs | [ scan("-?\\d+") | tonumber ] ) as $point ([];
  def mann_d($p): [.,$p] | transpose | map(.[0]-.[1]|abs) | add;
  (
    map([                                        # Foreach group
      first( .[]|mann_d($point)|select(. < 4) )  # ∃(p) range(3)
    ]|length) | indices(1)
  ) as $idx |

  if $idx != [] then #Add all points in range to the first group
    .[$idx[0]] = ([(.[$idx[0]]),(.[$idx[1:][]]),[$point]]|add) |
    del(.[$idx[1:][]]) # Remove trailing groups—completing merge
  else . + [[$point]] end # New group, If no indices(G)∈range(3)
) | length                # Finally output nbr of constellations
