#!/usr/bin/env jq -n -sR -f

#────────────────── Big-endian from_bits ────────────────────────#
def from_bits: [ range(length) as $i | .[$i] * pow(2; $i) ] | add;

inputs | rtrimstr("\n") / "\n\n"

# Parse live wires and gates #
| [ .[1] / "\n" | .[] / " " | del(.[-2]) ] as $gates
| [ .[0] / "\n" | .[]
    | [ scan("[xy]\\d{2}"), (scan("\\b[10]\\b")|tonumber) ]
    | {(.[0]): .[1]}
  ] as $wires

| { w: ( $wires | add ), g: $gates } |

until (isempty(.g[]);
  first( #            Pop first gate with live input wires          #
    .g[] as [$a,$o,$b,$r] | select(.w[$a] and .w[$b]) | [$a,$o,$b,$r]
  ) as [$a,$o,$b,$r] | .g = .g - [[$a,$o,$b,$r]] |

  def toi: if . == true then 1 else 0 end;

  if   $o == "AND" then .w[$r] = (( .w[$a] + .w[$b])      == 2 | toi)
  elif $o == "OR"  then .w[$r] = (( .w[$a] + .w[$b])      >= 1 | toi)
  elif $o == "XOR" then .w[$r] = (((.w[$a] + .w[$b]) % 2) == 1 | toi)
  else "Unexpected operator: \($o)" | halt_error end
) | .w # Final live wires

#   Get integer for final value on the z wires    #
| [ to_entries[] | select(.key | test("z\\d{2}")) ]
|  sort_by(.key) | [ .[].value ] | from_bits
