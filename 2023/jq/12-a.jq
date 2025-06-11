#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  # Parse inputs as:
  # sequence="..#..#" continguous_blocks = [1,2,3]
  inputs / " " | .[1] |= (. / "," | map(tonumber))
) as [$seq,$cont] (0;

  # Recursive function, for number of matches.
  def num_matches($seq;$cont):

    # Recursion end -> Easy case if $cont == []
    if $cont == [] then if $seq|test("#") then 0 else 1 end
    # Fast Recursion -> Trim input of "."
    elif $seq|test("^\\.+|\\.+$") then num_matches($seq|gsub("^\\.+|\\.$";""); $cont)

    # Otherwise
    else
      [ # First    # Trailing      # Space available = Sum of sizes + length  for
        # Group    # Groups        # intervals of at least 1 within, and with 1st
        $cont[0] , ($cont[1:] | ., ([add,length] | add))
      ] as [ $first, $groups, $space ] |

      # Testing all substrings before mininimum space taken by remaining groups
      reduce range(($seq|length)-$space-$first+1) as $i (0;
        # Sliding first group in available space, with required bounding "."
        ( [ (range($i)|"."), (range($first)|"#"), "." ] | add ) as $pos |

        if (
          [$seq, $pos] | map(explode) | all(      # All(.[]; .) for fast exit
            transpose[] | select(.[0] and .[1]);  # Compare strings  pairwise
            .[0] == .[1] or .[0] == 63   # $seq(i) == $pos(i)  or $seq(i) = ?
          )
        ) then
          # For each possible match, add sub_matches recursively
          . + (num_matches($seq[$pos|length:];$groups))
        else . end
      )
    end
  ;
  # Accumlate possible matches for all inputs
  . + num_matches($seq;$cont)
)
