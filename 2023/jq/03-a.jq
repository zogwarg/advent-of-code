#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Getting input with padding, and padded width
[ "." + inputs + "." ] as $inputs | ( $inputs[0] | length ) as $w |

# Working with flattened string, convert all symbols to '#'
[
  ([range($w) | "."]|join("")), # Padding
  $inputs[],
  ([range($w) | "."]|join(""))  # Padding
] | join("") | gsub("[^0-9.]";"#") as $inputs |

reduce (
  # Get all indices for symbols, in box pattern around symbols
  $inputs | indices("#")[] |
  . - $w -1  , . - $w , . - $w + 1 ,
  . - 1      , empty  , . + 1      ,
  . + $w - 1 , . + $w , . + $w + 1
) as $i (
  # Numbers containes bounding indices,
  # of numbers bordering symbols
  {numbers: []};

  # Test if current index isn't included in any found number
  def new_number($i): [ .numbers[] | .[0] <= $i and $i <= .[1] ] | any | not ;
  # Make "number" as bounding indices, by extending left and right
  def make_number($i):
    {a: $i, b: ($i+1 )}
      | until( $inputs[.a:.b] | test("^[^0-9]"); .a -= 1 )
      | until( $inputs[.a:.b] | test("[^0-9]$"); .b += 1 )
      | [ .a +1 , .b -1 ]
  ;

  # Add numbers if bordering symbol and new
  if ($inputs[$i:$i+1] | test("[0-9]")) and new_number($i) then .numbers += [ make_number($i) ] else . end
) |

# Output sum of all found numbers
[ .numbers[] | $inputs[.[0]:.[1]] | tonumber ] | add
