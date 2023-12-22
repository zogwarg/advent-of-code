#!/usr/bin/env jq -n -R -f

# Get boss stats
[ inputs | scan("\\d+") | tonumber ] as [$boss_hp, $boss_atk] |

{ # State at any given turn
  # --------------------------------
  $boss_hp,    # Remaining boss HP
  $boss_atk,   # Static    boss ATK
  # --------------------------------
  mana:   500, # Remaining   MANA
  spent:    0, # Total spent MANA
  hp:      50, # Remaining   HP
  armor:    0, # Current     SHD
  # --------------------------------
  shield:   0, # SHD Turns remaining
  poison:   0, # PSN Turns remaining
  recharge: 0. # RCH Turns remaining
} |


# Update statuses functions
def update_shield:
  if   .shield >  1 then .shield -= 1
  elif .shield == 1 then .shield -= 1 | .armor = 0 end
;
def update_poison:
  if .poison >  0 then .poison -= 1 | .boss_hp -= 3 end
;
def update_recharge:
  if .recharge >  0 then .recharge -= 1 | .mana += 101 end
;
def update_statuses:
  update_shield | update_poison | update_recharge
;

# Cast spells functions
def cast_magic_missile:
  if .mana >= 53 then
    .mana -= 53 | .spent += 53 | .boss_hp -= 4 | .cast += ["mm"]
  else
    empty
  end
;
def cast_drain:
  if .mana >= 73 then
    .mana -= 73 | .spent += 73 | .boss_hp -= 2 | .hp += 2 | .cast += ["d"]
  else
    empty
  end
;
def cast_shield:
  if .mana >= 113 and .shield == 0 then
    .mana -= 113 | .spent += 113 | .armor = 7 | .shield = 6 | .cast += ["s"]
  else
    empty
  end
;
def cast_poison:
  if .mana >= 173 and .poison == 0 then
    .mana -= 173 | .spent += 173 | .poison = 6 | .cast += ["p"]
  else
    empty
  end
;
def cast_recharge:
  if .mana >= 229 and .recharge == 0 then
    .mana -= 229 | .spent += 229 | .recharge = 5  | .cast += ["r"]
  else
    empty
  end
;

[ # Recursively play turns
limit(10;recurse(
  if .boss_hp <= 0 or .hp <= 0 or ( .recharge == 0 and .mana < 53 ) or (.spent > 3000) then
    empty
  else
    update_statuses |
    # Try casting poison first, as it's the best damage for mana spent.
    cast_poison,
    cast_magic_missile,
    cast_drain,
    cast_shield,
    cast_recharge,
    empty | update_statuses |
    if .boss_hp > 0 then .hp -= ([1, .boss_atk - .armor] | max) end
  end
) | select(.boss_hp <= 0)) # Keep states were boss was defeated.
] | min_by(.spent)         # First ones should have the lowest mana spent.

# Output minimum spent
| .spent
