#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"


inputs | rtrimstr("\n") / "\n\n" | .[0] as $LK | .[1] / "\n" |

if [$LK|.[0:1],.[-1:]] != ["#","."] then
  "Unexpected lookup table [first,last]: \([$LK[1,-1]])" | halt_error
end |

def pad_0: ([range(.[0]|length+4)|"."]|add) as $L | # Infinite "."  #
           [  $L,  $L,  "..\(.[])..",  $L,  $L  ] ; # On odd steps  #

def pad_1: ([range(.[0]|length+4)|"#"]|add) as $L | # Infinite "#"  #
           [  $L,  $L,  "##\(.[])##",  $L,  $L  ] ; # On even steps #

def lookup:
   [ length as $l | $l - indices("#")[] - 1 | pow(2;.) ] | add
   | $LK[.:.+1]
;

def enhance(pad):            pad |
  reduce (
    range(1;.[0]|length-1) as $x |
    range(1;     length-1) as $y |
      .[$y-1][$x-1:$x+2]
    + .[ $y ][$x-1:$x+2]
    + .[$y+1][$x-1:$x+2]
    | [($x-1),($y-1), lookup]
  ) as [$x,$y,$v] ([];.[$y] += $v)
;

enhance(pad_0) | enhance(pad_1) | [ .[] | scan("#") ] | length
