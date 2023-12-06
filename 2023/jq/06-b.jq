#!/usr/bin/env jq -n -R -f

[ input | gsub(" ";"") | scan("\\d+") | tonumber ][0] as $time |
[ input | gsub(" ";"") | scan("\\d+") | tonumber ][0] as $dist |

# Solve polymomial
# $x * ($time - $x) > $dist
# 1 * x^2 - $time * x + $dist = 0; a = 1, b = -$time, c = $dist

# delta = b^2 - 4 * a * c
# sqrt(delta) / 2 * a
( $time * $time - 4 * $dist | sqrt / 2 ) as $sqd |
( if $sqd == ($sqd | floor) then 1 else 0 end ) as $int_sq |

# Find roots: ( -b ± sqrt(delta) ) / 2
[ ( $time  / 2 ) + ($sqd, - $sqd) ]

# Interval between roots, is winning times
| map(floor) | $int_sq + .[0] - .[1]
