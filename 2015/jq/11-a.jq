#!/bin/sh
# \
exec jq -n -rR -f "$0" "$@"

# Get input password mapped to range: [0, 25]
inputs | explode | map(. - 97) as $password |
 "iol" | explode | map(. - 97) as $iol      |
# And list of confusing password characters |

if $password | length < 7 then
  "Password is too short!" | halt_error
elif $password[-6] == $password[-7] + 1 or $password[-6] == 25 then
  "Assumptions about input not met" | halt_error
end |

# Head of the password should not change. Carry #
$password[:-6] as $head | $password[-6] as $mid |

[  # Get fist availble double letters arrangement
    $password[-5:-3], # consecutive in the middle
  [ $password[-3], $password[-3] ],
    $password[-2:]
  | . as [$a,$b]
  | if $a >= $b then $a else $a + 1 end
] as [$aa, $b, $cc ] | #       ___aabcc         #

$head + (
  if $aa <= 23 and $b <= $aa + 1 then
    [ $mid ] + first(
        range($aa; 26) as $aa
      | [$aa, $aa, $aa + 1, $aa + 2, $aa + 2]
      | select(all(.[] != $iol[];.))
    )
  else
    [
      first(
        range($mid; 25) + 1 | select(all(. != $iol[]; .))
      ), 1, 1, 2, 3, 3
    ]
  end
) | map(. + 97) | implode
