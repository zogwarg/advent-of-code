#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

#            Parse as S = { "parent": ["children", ...] }           #
[ inputs / ": " | .[1] |= split(" ") | {(.[0]): .[1]} ] | add as $S |

#      Checking Accessibility from certain racks to others          #
( reduce ( [($S | keys[]), $S[][]] | unique[] ) as $s ({};
  def reaches($source): { head: [$source], reached: {} }     | until(
    isempty(.head[]);    .head[0] as $H | .head = .head[1:]  |
    reduce (
      ( $S[$H] | arrays[] ) as $n | select(.reached[$n]|not) | $n
    ) as $n (.;
      .head = .head + [$n] | .reached[$n] = true
    )
  );
  .[$s] = reaches($s).reached
)) as $reach |
def from_reaches($source; $target): $reach[$source][$target] == true;

#         Establising in which order fft and dac are visited        #
[ ["fft", "dac"], ["dac","fft"] | [ from_reaches(first;last) ] + . ]
| sort | [ .[][1] ] as [$B, $A] |

if [ .[][0] ]
 + [  # Making sure the racks have proper circuits   #
      from_reaches($A;    $A), from_reaches($B; $B),
      from_reaches("svr"; $A), from_reaches($B; "out")
   ] != [false,true,false,false,true,true]
then
  "No cycles please!" | halt_error
end

#      Pruning The DAG into three parts svr -> A -> B -> out       #
#        Only keeping racks that can reach each subgoal            #
| [ $reach["svr"]|"svr",keys[]|select(from_reaches(.; $A )) ] as $SA
| [ $reach[ $A  ]| $A , keys[]|select(from_reaches(.; $B )) ] as $AB
| [ $reach[ $B  ]| $B , keys[]|select(from_reaches(.;"out"))] as $BO
| def picky($R;$T): pick(.[$R[]])
    | pick(..|strings|select(any(. == ($R[], $T); .)))
    | .[] |= map(strings)
  ; [ $S |
      picky($SA; $A  ),
      picky($AB; $B  ),
      picky($BO;"out")
    ] as [$SA,$AB,$BO]

# Getting the reverse DAG graphs out -> B -> A -> svr #
| [ $SA, $AB, $BO | reduce (
    to_entries[] | .key as $k | .value[] | {v:.,$k}
  ) as {$k,$v} ( keys as $k | {} | .[$k[]] = [];
    .[$v] += [$k]
  )] as [$rSA, $rAB, $rBO]
|

def V($start; $target; $S; $R):
  { #   Visits BFS function   #
    head: [$start], visits: { "\($start)": 1 }, done: {},
  } |

  until (isempty(.head[]); .i += 1 |
    .head[0] as $h | .head = .head[1:] | .visits[$h] as $v |
    reduce (                      #  No double processing #
      ( $S[$h] | arrays[] ) as $n | select(.done[$h]|not) | $n
    ) as $n (.;
      .visits[$n] += $v |

      # Only queue racks, hose parents have all been visited #
      if all(($R[$n][]) as $r | .visits[$r]; .) then
        .head = .head + [$n]
      end
    ) | .done[$h] = true
  ) | .visits[$target]
;

V("svr";$A;$SA;$rSA) * V($A;$B;$AB;$rAB) * V($B;"out";$BO;$rBO)
