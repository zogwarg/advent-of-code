#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs | [scan("-?\\d+") | tonumber] ] | to_entries

# Get particles with lowest acceleration
| group_by(.value[-3:]|map(abs)|add) | .[0] |

def acc($speed;$acc):
  [$speed,$acc] | transpose | map(.[0]+.[1])
;

def speed($speed):
  $speed|map(abs)|add
;

map( # Increase time, until speed is increasing
  {key,speed: .value[3:6], acc: .value[6:],t:0} |
  until (speed(acc(.speed;.acc)) > speed(.speed);
    .speed = acc(.speed;.acc) | .t += 1
  )
) | max_by(.t).t as $max_t  |

map ( # Step forward until all particles are increasing in speed
  reduce range($max_t - .t) as $_ (.;.speed = acc(.speed;.acc) | .t += 1) |
  .speed = speed(.speed)
) |

# Output particle with lowest acceleration
# And lowest speed in the long run
min_by(.speed).key
