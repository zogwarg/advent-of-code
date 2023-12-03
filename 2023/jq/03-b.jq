#!/usr/bin/env jq -n -R -f

# Getting input with padding, and padded width
[ "." + inputs + "." ] as $inputs | ( $inputs[0] | length ) as $w |

# Working with flattened string, only keep gear '*' symbols
[
  ([range($w) | "."]|join("")), # Padding
  $inputs[],
  ([range($w) | "."]|join(""))  # Padding
] | join("") | gsub("[^0-9*]";".") as $inputs |

# Iterate over index positions of all gears
reduce ($inputs | indices("*")[]) as $i (
  0;
  # Re-use part-1 functions
  def new_number($i):
    [ .numbers[] | .[0] <= $i and $i <= .[1] ] | any | not
  ;
  def make_number($i):
    {a: $i, b: ($i+1 )}
      | until( $inputs[.a:.b] | test("^[^0-9]"); .a -= 1 )
      | until( $inputs[.a:.b] | test("[^0-9]$"); .b += 1 )
      | [ .a +1 , .b -1 ]
  ;
  # Reset and add numbers for each "box" ids
  def add_numbers($box_idx):
    reduce $box_idx[] as $i ({numbers:[]};
      if ($inputs[$i:$i+1] | test("[0-9]")) and new_number($i) then
        .numbers += [ make_number($i) ]
      else
        .
      end
    )
  ;
  add_numbers([
    $i - $w -1 , $i - $w , $i -$w + 1 ,
    $i - 1     , empty   , $i + 1     ,
    $i + $w - 1, $i + $w , $i + $w + 1
  ]).numbers as $numbers |

  if $numbers | length == 2 then
    # Add product if exactly two bordering numbers
    . += ( $numbers | map($inputs[.[0]:.[1]]|tonumber) | .[0] * .[1] )
  else
    .
  end
)
