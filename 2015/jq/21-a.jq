#!/usr/bin/env jq -n -R -f

# C D A | Cost Damage Armor
[
 [8 ,4,0], # Knifey thing
 [10,5,0], # Stabby thing
 [25,6,0], # Smashy thing
 [40,7,0], # Slashy thing
 [74,8,0]  # Cleavy thing
] as $weapons |

[
  [13 ,0,1], # Cowwey thing
  [31 ,0,2], # Ringey thing
  [53 ,0,3], # Flatty thing
  [75 ,0,4], # Layery thing
  [102,0,5], # Knight thing
  [0  ,0,0]  # Emptey thing
] as $armor |

[
  [25 ,1,0], # D+1
  [50 ,2,0], # D+2
  [100,3,0], # D+3
  [20 ,0,1], # A+1
  [40 ,0,2], # A+2
  [80 ,0,3], # A+3
  [0  ,0,0]  # X+0
] as $rings |

[ inputs | scan("\\d+") | tonumber ] as [$boss_hp, $boss_atk, $boss_def] |

reduce (
  [ $weapons, $armor, $rings, $rings ]
  | combinations
  | select(.[-1] != .[-2] or .[-1] == [0,0,0])
  | transpose
  | map(add)
) as [$cost, $atk, $def] (
  1000;

  # Damage per turn calculation
  ([$atk - $boss_def, 1]|max) as $dpt |
  ([$boss_atk - $def, 1]|max) as $boss_dpt |

  # Comparing number of turns to exhaust HP
  if ( $boss_hp / $dpt ) <= (100 / $boss_dpt) then
    [$cost, .] | min
  end
)
