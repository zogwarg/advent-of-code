#!/usr/bin/env jq -n -R -f

# Utility function
def assert($stmt; $msg): if $stmt == false then $msg | halt_error end;

# Getting disks with [x,y,size,used,avail,use_percentage]
[ inputs | [ scan("\\d+") | tonumber ] ][1:] as $disks |

([ $disks[][0] ] | max + 1 ) as $W |
([ $disks[][1] ] | max + 1 ) as $H |

[ # Get all viable pairs
  $disks
| combinations(2)
| select(.[0][0:2] < .[1][0:2])
| select(
    (.[0][3] > 0 and .[0][3] <= .[1][4]) or
    (.[1][3] > 0 and .[1][3] <= .[0][4])
  )
] as $pairs |

assert(
  all($pairs[]; contains([$pairs[0][1]]));
  "There should be one empty node"
) |

$pairs[0][1][0:2] as $empty_disk |

reduce (
  $pairs | map(sort_by(. == $pairs[0][1]) | .[0][0:2]) | .[]
) as [$x,$y] (
  [ range($H) as $y | [ range($W) as $x | "#" ]]|
  .[$empty_disk[1]][$empty_disk[0]] = "E";
  .[$y][$x] = " "
) | . as $map |

assert(
  ( $map[0] | unique ) == [" "] and
  ( $map[1] | unique ) == [" "];
  "The first two rows should not have walls"
) |

($map | map(unique) | indices([[" ","#"]])) as $wall_idx |

assert(
  ($wall_idx | length ) == 1 and ($wall_idx[0] < $empty_disk[1]);
  "There should be only one horizontal wall above the Empty disk"
) |

($map[$wall_idx[0]] | indices("#") | sort) as $wall_span |

assert(
  $wall_span == [range($wall_span[0];$W)] and $wall_span[0] <= $empty_disk[0];
  "The wall is uninterrupted, reaches max X, and overhangs the Empty disk"
) |

# Given these conditions
# Here is the number of moves required
 ( $empty_disk[0] - $wall_span[0] + 1 ) # Move Left
+  $empty_disk[1]                       # Move Up
+  $W - $wall_span[0]                   # Move Right          .G. .G. .G. _G. G_.
+ ( $W - 2 ) * 5                        # Move the goal left  .._ ._. _.. ... ...
