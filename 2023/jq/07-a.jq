#!/usr/bin/env jq -n -R -f

# Strength order
"AKQJT98765432" as $strength |

# Define hand type tests
def five: . / "" | group_by(.) | map(length) | max == 5;
def four: . / "" | group_by(.) | map(length) | max == 4;
def full: . / "" | group_by(.) | map(length) | sort == [2,3];
def three: . / "" | group_by(.) | map(length) | sort == [1,1,3];
def twopair: . / "" | group_by(.) | map(length) | sort == [1,2,2];
def pair: . / "" | group_by(.) | map(length) | sort == [1,1,1,2];
def high: . / "" | group_by(.) | map(length) | sort == [1,1,1,1,1];

# Parse all hands
[  inputs / " " | .[1] |= tonumber ] |

# Sort hands, lower is stronger
sort_by(
  [
    # Hand type tuple, eg five: (false, true, true, true, true, true, true)
    [ ( .[0] | (five, four,full,three,twopair,pair,high) | not ) ],
    # In remaining order relative index of card eg AAAAK = [0,0,0,0,1]
    ( ( .[0] / "" | .[] ) as $s | $strength | index($s) )
  ]
)

# Transpose to [[hand, bid], rank] and accumulate bid * rank
| [ . , ( [range(length) + 1 ] | reverse) ] |
reduce transpose[] as [[$h,$bid], $rank] (0; . + $bid * $rank)
