#!/usr/bin/env jq -n -R -f

# Getting disks with [x,y,size,used,avail,use_percentage]
[ inputs | [ scan("\\d+") | tonumber ] ][1:] as $disks |

reduce ( # Count viable pairs of disk
  $disks # Where one can send data to another
| combinations(2)
| select(.[0][0:2] < .[1][0:2])
| select(
    (.[0][3] > 0 and .[0][3] <= .[1][4]) or
    (.[1][3] > 0 and .[1][3] <= .[0][4])
  )
| 1
) as $_ (0; . + 1)
