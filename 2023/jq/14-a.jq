#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Dish to grid
[ inputs / "" ]

# Tilt UP
| transpose                       # Transpose, for easier RE use
| map(                            #
  ("#" + add) | [                 # For each column,   replace '^' with '#'
    scan("#[O.]*") | [            # From '#' get empty spaces and 'O' rocks
      "#", scan("O"), scan("\\.") # Let gravity do it's work.
    ]                             #
  ] | add[1:]                     # Add groups back together
 )                                #
| transpose                       # Transpose back

# For each row, count  'O'  rocks
| map(add | [scan("O")] | length)

# Add total load on "N" beam
| [0] + reverse | to_entries
| map( .key * .value ) | add
