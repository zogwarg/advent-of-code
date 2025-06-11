#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Get all [ node, [node_val, <sum_children_val>, <0> ] , [ ..<chlidren> ]]
[ inputs | [ scan("[a-z]+|\\d+") ] | .[1] |=  tonumber  | .[1:] |= map([.]) ] |

# For all nodes without children set:
# [node_val, ..<sum_children_val> ] = [node_val, 0]
( .[] | select(.[2:] == []) | .[1] ) |= [ .[], 0 ] |

# Until all sum_children_val are filled, do
until([ .[] | .[1] | length > 1 ] | all;
   # For all non "used" filled sum_children_val entries, try adding to others
   reduce (.[] | .[0:2] | select(.[1] | length == 2) | [.[0], (.[1] | add)] ) as [$n, $v] (.;
      # Substitute ["child"] with ["child", child_value_sum ]
      (.[] | select((.[1] | length  == 1 ) and ( [ .[2:][] | select(length == 1) | .[0] == $n ] | any )))  |= (
        ( .[2:][] | select(.[0] == $n) ) |= [$n, $v] |
        if [ .[2:][] | length > 1 ] | all then
           # If all child_sums enters, set sum_children_val
          .[1] = [ .[1], ([ .[2:][][1] ]) | add ]
        else
          .
        end
      ) |
      # Set state as "used"
      # [node_val, sum_children_val, null ] = [node_val, sum_children_val, 0 ]
      ( .[] | select(.[0] == $n ) ) |= ( .[1] += [0] )
   )
) |

# Make hash_table of nodes
( [ .[] | {(.[0]): .[1][:-1] } ] | add ) as $nodes |
# Find all unbalanced value and correct tem
[
  .[] | .[2:] | select(.[0]?[1] as $s | $s and ( [ .[][1] != $s ] | any ))
   | ( group_by(.[1]) | sort_by(length) | [ .[0][][], .[1][0][1] ] ) as [$n, $c, $o ] |
   $nodes[$n][0] + $o - $c
]

# Smallest one, is the "leafiest"
| min
