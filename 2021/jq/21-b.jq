#!/usr/bin/env jq -n -R -f

[ inputs | scan("\\d+") | (10+tonumber-1) % 10 ] as [$_,$p1,$_,$p2] |

(
  [ [1,2,3]|combinations(3)|add ] | group_by(.) | map([.[0], length])
) as $throws |

[
  ($p1,$p2) as $pos | (
    .[0][0][$pos] = 1 |      # Count by = (Score x turn x position) #
    reduce range(11) as $t ( # Max 11 turns since min_score(2t) = 2 #
      .;
      reduce (
        path(..|numbers)|select(.[0] < 21 and .[1]==$t)
      ) as [$score,$turn,$pos] (
        .;
        getpath([$score,$turn,$pos]) as $prev |
        reduce (
          $throws[]
        ) as [$ds,$cs] (
          # Build up state count by throw distribution #
          .;   .[$score + (($pos + $ds) % 10 + 1 )]
                [$t+1]
                [($pos + $ds) % 10] += $prev * $cs
        )
      )
    ) |
    # Independant universes where player achieves a score #
    #        of 21 by turn t, in array at index t         #
    reduce (
      ( path(..|numbers) | select(.[0] >= 21) ) as $p |
      [ $p[1], getpath($p) ]
    ) as [$t,$c] ([];.[$t] += $c ) | (..|nulls) = 0
  )
] |

reduce transpose[1:][] as [$p1, $p2] (
  [0, 1]; # Universes [ with p1 victory, with no p2 victory ] #
  .[0]  =  .[0] + $p1 * .[1]  | .[1]  =  .[1] * 3 * 3 * 3 - $p2
)

| .[0] #  Universes with p1 (first player advantage) victory  #
