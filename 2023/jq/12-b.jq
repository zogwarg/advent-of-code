#!/usr/bin/env jq -n -R -f

reduce (
  # Option to run in parallel using xargs
  # Eg: ( seq 0 9 | \
  #        xargs -P 10 -n 1 ./2023/jq/12-b.jq input.txt --argjson s 10 --argjson i \
  #      ) | jq -s add
  # Execution time 17m10s -> 20s
  if $ARGS.named.s and $ARGS.named.i then #
    [inputs] | to_entries[] | select(.key % $ARGS.named.s == $ARGS.named.i) | .value / " "
  else
    inputs / " "
  end |
  # Parse inputs as:
  # sequence="..#..#" continguous_blocks = [1,2,3]
  .[1] |= (. / "," | map(tonumber)) |
  .[0] |= ([ range(5) as $i | . ] | join("?"))     |
  .[1] |= ([ range(5) as $i | . ] | add)
  | debug
) as [$seq,$cont] ({c:0,memo:{}};

  # Refactoring from  part A to include  "memoized"  state.
  # Being careful to pass it correctly at each reduce step.
  # Unique key for dict  is $seq+($cont|implode) [garbagey]

  # Recursive function, for number of matches.
  def num_matches($seq;$cont;$memo):

    # Don't include trivial cases in memoized dictionary.
    # Recursion end -> Easy case if $cont == []
    if $cont == [] then if $seq|test("#") then {c:0,$memo} else {c:1,$memo} end
    # Fast Recursion -> Trim input of "."
    elif $seq|test("^\\.+|\\.+$") then num_matches($seq|gsub("^\\.+|\\.$";"");$cont;$memo)

    # Return "memoized" value if found.
    elif $memo[$seq+($cont|implode)] then $memo[$seq+($cont|implode)] | {c:.,$memo}

    # Otherwise
    else
      [ # First    # Trailing      # Space available = Sum of sizes + length  for
        # Group    # Groups        # intervals of at least 1 within, and with 1st
        $cont[0] , ($cont[1:] | ., ([add,length] | add))
      ] as [ $first, $groups, $space ] |

      # Testing all substrings before mininimum space taken by remaining groups
      reduce range(($seq|length)-$space-$first+1) as $i ({c:0,$memo};
        # Sliding first group in available space, with required bounding "."
        ( [ (range($i)|"."), (range($first)|"#"), "." ] | add ) as $pos |
        if (
          [$seq, $pos] | map(explode) | all(      # All(.[]; .) for fast exit
            transpose[] | select(.[0] and .[1]);  # Compare strings  pairwise
            .[0] == .[1] or .[0] == 63   # $seq(i) == $pos(i)  or $seq(i) = ?
          )
        ) then
          # For each possible match, add sub_matches recursively
          (num_matches($seq[$pos|length:];$groups;.memo)) as {$c,$memo} |
          .c += $c | .memo += $memo
        else . end
      )
    end | .memo[$seq+($cont|implode)] = .c
  ;
  # Accumlate possible matches for all inputs
  num_matches($seq;$cont;.memo) as {$c,$memo} |
  .c += $c | .memo += $memo
) | .c
