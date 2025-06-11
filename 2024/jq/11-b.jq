#!/bin/sh
# \
exec jq -n -f "$0" "$@"

reduce (inputs|[.,0]) as [$n,$d] ({};     debug({$n,$d,result}) |
  def next($n;$d): # Get next           # n: number, d: depth  #
      if $d == 75                    then          1
    elif $n == 0                     then [1          ,($d+1)]
    elif ($n|tostring|length%2) == 1 then [($n * 2024),($d+1)]
    else #    Two new numbers when number of digits is even    #
      $n|tostring| .[0:length/2], .[length/2:] | [tonumber,$d+1]
    end;

  #         Push onto call stack           #
  .call = [[$n,$d,[next($n;$d)]], "break"] |

  last(label $out | foreach range(1e9) as $_ (.;
    # until/while will blow up recursion #
    # Using last-foreach-break pattern   #
    if .call[0] == "break" then break $out
    elif
      all( #     If all next calls are memoized        #
          .call[0][2][] as $next
        | .memo["\($next)"] or ($next|type=="number"); .
      )
    then
      .memo["\(.call[0][0:2])"] = ([ #                 #
          .call[0][2][] as $next     # Memoize result  #
        | .memo["\($next)"] // $next #                 #
      ] | add ) |  .call = .call[1:] # Pop call stack  #
    else
      #    Push non-memoized results onto call stack   #
      reduce .call[0][2][] as [$n,$d] (.;
        .call = [[$n,$d, [next($n;$d)]]] + .call
      )
    end
  ))
  # Output final sum from items at depth 0
  | .result = .result + .memo["\([$n,0])"]
) | .result
