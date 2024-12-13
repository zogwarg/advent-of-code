#!/usr/bin/env jq -n -sR -f

{ #                   Parse monkey behaviour                    #
  monkeys: [ inputs | rtrimstr("\n") | split("\n\n")[] / "\n" | {
    ini: [ .[1] | scan("\\d+") | tonumber ],
    div: [ .[3] | scan("\\d+") | tonumber ][0],
    aye: [ .[4] | scan("\\d+") | tonumber ][0],
    nay: [ .[5] | scan("\\d+") | tonumber ][0],
    ops: (
      .[2]
      | split(" = ")[1]
      | [ scan("\\*|\\+"), (scan("\\d+")|tonumber) ]
    ),
  }]
}

# Represents number only as residuals for each divisibility test #
| ( [ .monkeys[].div ] | sort )                          as $mods
| ( $mods | with_entries({key:"\(.value)",value:.key}) ) as $idx
| .monkeys[].ini[] |=  [ $mods[] as $m | . % $m ] |

reduce range(10000) as $_ (.;
  reduce range(.monkeys|length) as $i (.;
    .monkeys[$i] as {$div,$aye,$nay,ops:[$op,$x]} |
    reduce (.monkeys[$i].ini[] | [.,$mods] | transpose) as $num (
      .monkeys[$i].ini = [];                 # Empty items queue #
      .monkeys[$i].did += 1 |                # Tally inspections #
      #                       Do operation                       #
      ( if $op == "+" then $num | map((first +  $x  ) % last)
      elif     $x     then $num | map((first *  $x  ) % last)
                      else $num | map((first * first) % last)
      end) as $num | # Through updating all of the residuals.
      #                   Pass to next monkey                       #
      if $num[$idx["\($div)"]] == 0 then .monkeys[$aye].ini += [$num]
                                    else .monkeys[$nay].ini += [$num]
                                    end
    )
  )
)

#         Output total monkey business           #
| .monkeys | map(.did) | sort_by(-.) | .[0] * .[1]
