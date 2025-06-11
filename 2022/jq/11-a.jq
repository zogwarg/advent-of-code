#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

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
} |

reduce range(20) as $_ (.;
  reduce range(.monkeys|length) as $i (.;
    .monkeys[$i] as {$div,$aye,$nay,ops:[$op,$x]} |
    reduce .monkeys[$i].ini[] as $num (
      .monkeys[$i].ini = [];                 # Empty items queue #
      .monkeys[$i].did += 1 |                # Tally inspections #
      #                       Do operation                       #
      ( if $op == "+" then $num + $x
      elif     $x     then $num * $x
                      else $num * $num end / 3 | trunc) as $num |
      #                   Pass to next monkey                    #
      if $num % $div == 0 then .monkeys[$aye].ini += [$num]
                          else .monkeys[$nay].ini += [$num] end
    )
  )
)

#         Output total monkey business           #
| .monkeys | map(.did) | sort_by(-.) | .[0] * .[1]
