#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

32 as $min |

[ limit(3; inputs)
  | [ scan("\\d+") | tonumber ]
  | . as [$id,$oro,$cro,$sro,$src,$gro,$grs]
  | debug({$id,$oro,$cro,$sro,$src,$gro,$grs})
  | last(label $out | foreach range(1e9) as $_ (
      { # DFS  #
        stack: [
          { min: 0, bots: [1,0,0,0], ore: [0,0,0,0] }
        ],
        # Max geodes
        max: 0
      };

      if .break then break $out end |

      # Popping stack and state
      { stack, max, x, push:[] } + .stack[0] | .stack = .stack[1:] |

      # Max reachable geodes, used for trimming branches #
      def max_reachable:
        .ore[3] + ( 2 + $min - .min ) * ( 1 + $min - .min ) / 2 +
        .bots[3] * ( $min - .min )
      ;

      if .min < $min and max_reachable > .max then
        .min = .min + 1 | .bots as $b | .ore as $o |
        .ore = ([ $o,$b ] | transpose | map(add))  |
        if .ore[3] > .max then
          .max = .ore[3] |
          .x = {min,bots,ore}
        end |

        .push = [ { min,bots,ore } ] |

        if
          $o[0] >= $oro and $o[0] < $oro + $b[0]
        then
          .push = [
              .ore[0] = .ore[0] - $oro
            | .bots[0] = .bots[0] + 1
            | {min, bots, ore}
          ] + .push
        end |

        if
          $o[0] >= $cro and $o[0] < $cro + $b[0]
        then
          .push = [
              .ore[0] = .ore[0] - $cro
            | .bots[1] = .bots[1] + 1
            | {min, bots, ore}
          ] + .push
        end |

        if
                $o[0] >= $sro        and $o[1] >= $src
          and ( $o[0] <  $sro + $b[0] or $o[1] <  $src + $b[1] )
        then
          .push = [
              .ore[0] = .ore[0] - $sro | .ore[1] = .ore[1] - $src
            | .bots[2] = .bots[2] + 1
            | {min, bots, ore}
          ] + .push
        end |

        if
                $o[0] >= $gro        and $o[2] >= $grs
          and ( $o[0] <  $gro + $b[0] or $o[2] <  $grs + $b[2] )
        then
          .push = [
              .ore[0] = .ore[0] - $gro | .ore[2] = .ore[2] - $grs
            | .bots[3] = .bots[3] + 1
            | {min, bots, ore}
          ] + .push
        end |

        .stack = (
          [ .max as $m | .push[] | select(max_reachable>$m) ] +
          .stack
        )
      end |
      if isempty(.stack[]) then .break = true end
    ))
  | debug({$id,max,x}) | .max
] | .[0] * .[1] * .[2]
