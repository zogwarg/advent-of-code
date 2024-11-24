#!/usr/bin/env jq -n -R -f

10007 as $N | 2019 as $card |

# Part A doesn't really need optimization, but here we go
#
# ┌──────────────────────────────────┐
# │ F(i)      =  a * i +    b    % N │ Steps = Function
# ├──────────────────────────────────┤
# │ D(i,null) = -1 * i + (N - 1) % N │ - Deal new stack
# │ D(i,   n) =  n * i +    0    % N │ - Deal with inc
# │ C(i,   n) =  1 * i +    b    % N │ - Cut  with inc
# └──────────────────────────────────┘
#
# F(G(i)) = ( fa * ga % N ) * i + ( fa * ga + fb % N ) % N

reduce (
  inputs | [ scan("^[cd]"), (scan("-?\\d+")|tonumber) ] as [$op,$n] |
  [ #################################   a       b    #
      if $op == "d" and ($n|not) then (-1), ($N - 1) # Deal new stack
    elif $op == "d"              then ($n), (   0  ) # Deal with inc
                                 else ( 1), ( -$n  ) # Cut  with inc
                                  end                #
  ]
) as [$a, $b] ({ a: 1, b: 0} ; # Identity start
  .a = .a * $a % $N | .b = ( $a * .b + $b ) % $N
)

| ( .a * $card + .b ) % $N # Final card position
