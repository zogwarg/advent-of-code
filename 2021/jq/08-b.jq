#!/usr/bin/env jq -n -R -f

# Get list of segments [ [..ref], [..out] ]
[ inputs / " | " | [ .[] / " " | [ .[] | . / "" | sort ]]] |

[
  .[] | (
    # Using ref to build ( segments -> num ) map
     .[0] |
    # We can obtain 1-4-7-8 immediately
    ( .[] | select(length==2)) as $d1                                 | . - [$d1] |
    ( .[] | select(length==4)) as $d4                                 | . - [$d4] |
    ( .[] | select(length==3)) as $d7                                 | . - [$d7] |
    ( .[] | select(length==7)) as $d8                                 | . - [$d8] |
    # Next by Intersection of segments we can deduce the orthers      |           |
    ( .[] | select((length == 6) and (. - $d4 | length == 2))) as $d9 | . - [$d9] |
    ( .[] | select((length == 6) and (. - $d7 | length == 3))) as $d0 | . - [$d0] |
    ( .[] | select((length == 6) and (. - $d7 | length == 4))) as $d6 | . - [$d6] |
    ( .[] | select($d6-.|length==1)) as $d5                           | . - [$d5] |
    ( .[] | select($d9-.|length==1)) as $d3                           | . - [$d3] |
                                                                        . as[$d2] |
    {
      ($d0|add): 0,
      ($d1|add): 1, ($d2|add): 2, ($d3|add): 3,
      ($d4|add): 4, ($d5|add): 5, ($d6|add): 6,
      ($d7|add): 7, ($d8|add): 8, ($d9|add): 9
    }
  ) as $to_num |

  # Decyphering output number
  .[1] | map(add) |

  1000 * $to_num[.[0]] +
   100 * $to_num[.[1]] +
    10 * $to_num[.[2]] +
     1 * $to_num[.[3]]
]

# Sum of output values
| add
