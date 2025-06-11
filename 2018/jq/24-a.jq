#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

inputs / "\n\n" | [
  .[] / "\n" | .[1:] | [
      .[] | select(length > 0) | [
      (scan("\\d+")|tonumber),                    # UNT, HP, ATK, SPD
       scan("\\w+(?= damage)"),                   # Attack   type
      [scan("(?<=immune to )[^;)]+") /", " |.[]], # Immunity List
      [scan("(?<=weak to )[^;)]+")   /", " |.[]]  # Weakness List
    ]
  ]
] | { units: ((.[0]|map(.+["M"])) + (.[1]|map(.+["I"]))) } |

until (
  isempty(.units[] | select(.[-1] == "M" )) or # Until: Either side
  isempty(.units[] | select(.[-1] == "I" )) ;  # has been wiped out
  .by_atk = ( .units | sort_by(-(.[0]*.[2]),-.[3])) | # Sort(ATK,s)
  .target = .by_atk  | .init = [] |

  until (
    isempty(.by_atk[]); .by_atk[0] as [$U,$H,$K,$S,$T,$IL,$WL,$G] |
    .by_atk = .by_atk[1:] |
    def mul($il;$wl;$t): if $wl|contains([$t]) then 2 # DMG x bonus
                       elif $il|contains([$t]) then empty # non DMG
                                               else 1 end; # normal

    (
      [ # For every available target
        .target[]|select(.[-1]!=$G) as[$u,$h,$k,$s,$t,$il,$wl,$g] |
        [
          mul($il; $wl; $T )| # Sorted by:
             ( $U * $K * . ), # - DMG_DEALT
             ( $u * $k     ), # - DMG_RECEV
             (      $s     ), # - Target Initative
             (       .     )
        ]
      ] | max
    ) as [ $_, $_, $s, $m ] | # Save target "id" and dmg multiplier

    .init += [if $s then [$S,$s,$m]  else empty end] # Add to queue
    | del( .target[] | select( .[3]==$s ) ) # Remove from available
  )

  | .init |= sort_by(-.[0]) | # Roll for initiative then sort queue

  until (
    isempty(.init[]);  .init[0] as [$S,$s,$m] | .init = .init[1:] |
    (.units[] | select(.[3] == $S)) as [$U,$H,$K,$S,$T,$IL,$WL,$G]|
    (
      .units[]
      | select( .[3] == $s )  as [  $u,$h,$k,$_,$t,$il,$wl,$g ]   |
      ( $u - ( ($U*$K*$m) / $h | floor )) as $nu |
      if $nu <= 0 then null else [ $nu,$h,$k,$s,$t,$il,$wl,$g ] end
    ) as $upd | if $upd then (.units[]|select(.[3]==$s))= $upd else
      del(.units[]|select(.[3]==$s)) | #──┐└─── Update damaged unit
      del( .init[]|select(.[0]==$s))   #──┴──── Remove if wiped out
    end
  )
)

# Output total surviving units
| [ .units[][0] ] | add
