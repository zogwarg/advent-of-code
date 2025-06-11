#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

[ inputs | [scan("\\b[A-Z]\\b")] ] |

( "A" | explode | .[0] - 1 ) as $A |

# Number of workers | Min time per task
5 as $num_w         | 60 as $num_secs |

# All steps and requirements
{
  steps: ([.[][] ] | unique ),
  reqs: (.),
  workers: [ range($num_w) | "" ],
  out: [],
  time: 0
}

# Until no more requirements
| until (( .reqs | length == 0 );
  .time as $t |

  # Pop output of any completed workers
  reduce (
    [ .workers , [range($num_w)] ]
    | transpose[]
    | select((.[0] | type == "array" ) and .[0][1] <= $t)
  ) as [[$s], $i] (.;
    .out += [$s] |
    .workers[$i] = "" # Worker is ready
  ) |

  # Filter out requirements, with completed tasks
  .out as $out | .reqs |= ([
    .[] | select([.[0]] - $out | length > 0)
  ]) |

  # Get steps, ready for worker
  (.steps - [ .reqs[][1] ] | sort ) as $ready |

  # Merge available workers, and available tasks
  reduce (
    [ .workers , [range($num_w)] ]
    | [ transpose[] | select(.[0] == "") | .[1] ]
    | [ . , $ready ] | transpose[]
    | select(all)
  ) as [$i, $s] (.;
    # Add task, with completion time
    .workers[$i] = [ $s, $t + $num_secs + ($s | explode[0]) - $A ] |
    .steps -= [$s]
  ) |

  # Leaving pretty debug
  ( "\(.time)\(.time | tostring | [range(3 - length) | " " ] | join("") ) \([.workers[] | [ .. | strings | select(. != "") ] | .[0] // "." ] | join(" ")) \(.out | join(""))" | debug ) as $d |
  .time += 1
) |

# Output time at last output
[ .time - 1 , .workers[] | arrays | debug[1] ] | max
