#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

([
     inputs/ "" | map(tonumber? // -1) | to_entries
 ] | to_entries | map( # '.' = -1 for handling examples #
     .key as $y | .value[]
   | .key as $x | .value   | { "\([$x,$y])":[[$x,$y],.] }
)|add) as $grid | #           Get indexed grid          #

[
  ($grid[]|select(last==0)) | [.] |    #   Start from every '0' head
  recurse(                             #
    .[-1][1] as $l |                   # Get altitude of current trail
    (                                  #
      .[-1][0]                         #
      | ( .[0] = (.[0] + (1,-1)) ),    #
        ( .[1] = (.[1] + (1,-1)) )     #
    ) as $np |                         #   Get all possible +1 steps
    if $grid["\($np)"][1] != $l + 1 then
      empty                            #     Drop path if invalid
    else                               #
    . += [ $grid["\($np)"] ]           #     Build path if valid
    end                                #
  ) | select(last[1]==9)               #   Only keep complete trails
    | . |= [first,last]                #      Only Keep start/end
]

# Get score = sum of unique start/end pairs.
| group_by(first) | map(unique|length) | add
