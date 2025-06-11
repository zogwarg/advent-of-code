#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs
  | [  scan("-?\\d+") | tonumber ]  | [ .[0:2], .[2:] ] | transpose
  | [ map(.[0]) , ( map(.[1] - .[0] | abs) | add ) ] as [[$x,$y],$d]
  | ($d - ($y - 2000000 | abs)) as $D | select($D > 0)
  | [ $x - $D, $x + $D ] # Get segment intersection with 2000000 line
) as [ $x1, $x2 ] ({s:[]};
  .c = [$x1,$x2]                          # Set cur candidate segment
  | reduce .s[] as [$X1, $X2] (
      .s = [];
      if $X2 < .c[0] or .c[1] < $X1 then  # Keep non intersecting
        .s += [[$X1,$X2]]                 # segments
      else
        .c = ([$X1,$X2,.c[]] | [min,max]) # Merge intersecting
      end                                 # segments with current one
    )
  | .s = .s + [.c]                        # Add cur segment to list
) | [ .s[] | .[1] - .[0] ] | add          # Sum extend of all segments
