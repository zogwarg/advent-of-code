#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

256 as $size | # Setting loop size

reduce ( # Foreach input as "$i" included chars
  inputs / "," | .[] | tonumber
) as $i ({seq: [range($size)], pos: 0, off: 0 };

    # $b = number of chars looped back from start 0
  ( # $p = current pos, $pi end capped at loop size
    .pos + $i - $size  | if . > 0 then . else 0 end
  ) as $b | .pos as $p |([$p+$i,$size]|min) as $pi|

  # Get the current sub-set of seq,  and reverse it
  ( .seq[$p:$pi] + .seq[0:$b] | reverse ) as $rev |
  .seq[$p:$pi] = $rev[0:$pi-$p] | #Map "rev" to end
    .seq[0:$b] = $rev[$pi-$p:]  | #Map "rev" to beg

  # Update/loop .pos , and increase the offset by 1
  .pos+=($i + .off) | .pos|=(. % $size) | .off += 1

  # Output product of the first two elements in seq
) | .seq[0] * .seq[1]
