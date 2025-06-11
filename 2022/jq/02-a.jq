#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Define moves from elf and me
[ "A", "B", "C" ] as $elf |
[ "X", "Y", "Z" ] as $me |

[
  # Generate all combinations of  ( elf move X my move )
  [ $elf, $me ] | combinations |

  # Save moves
  . as [$e, $m] |

  # Get result of 3 for tie, 0 for loss and 6 for win.
  [ 3, 0, 6 ][( ($elf | index($e)) - ($me | index($m)) + 3 ) % 3 ] as $res |

  # Get bonus of 1 for Rock, 2 for paper and 3 for scissors
  (($me | index($m)) + 1 ) as $bonus |

  # Make key for  { key -> score } map
  join(" ") as $key |

  { ($key): ($res + $bonus) }
] | add as $score_map |

## Get scores for inputs
[
  inputs | $score_map[.]
] |

# Total expected score
add
