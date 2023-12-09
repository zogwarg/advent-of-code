#!/usr/bin/env jq -n -R -f

# Get LR instructions
( input / "" | map(if . == "L" then 0 else 1 end )) as $LR |
( $LR | length ) as $l |

# Make map {"AAA":["BBB","CCC"], ...}
(
  [
    inputs | select(.!= "") | [ scan("[A-Z]{3}") ] | {(.[0]): .[1:]}
  ] | add
) as $map |

# List primes for GCM test / factorization
[
  2, 3, 5, 7, 11, 13, 17, 19,
  23, 29, 31, 37, 41, 43, 47,
  53, 59, 61, 67, 71, 73, 79,
  83, 89, 97
] as $primes |

reduce (
  $map | keys[] | select(test("..A")) | { s: 0, i: 0, c: .} |

  # For each "..A" starting position
  # Produce visited [ "KEY", pos mod $l ], until loop is detected
  until (.i as $i | .[.c] // [] | contains([$i]);
    .s as $s | .i as $i | .c as $c        |
    $map[$c][$LR[$i]] as $next            | # Get next KEY
    .[$c] = (( .[$c] // [ $s ] ) + [$i] ) | # Append ( .s ≡ $l ) to array for KEY (first = .s non mod)
    .s = ( $s + 1 )  | .i = (.s % $l )    | # Update cursors, for next iteration
    .c = $next
  )
  | .[.c][0] as $start_loop_idx | (.s - $start_loop_idx) as $loop_size
  | [ to_entries[] | select(.key[-1:] == "Z") ]
  | if (
      length != 1                                           # Only one ..Z per loop
      or ( .[0].value[0] != $loop_size )                    # First ..Z idx = loop size
      or ( [ .[0].value[0] / $l ] | inside($primes) | not ) # loop_size = ( prime x $l )
      or ( .[0].value[0] / $l  > $l )                       # GCM(loop_sizes) = $l
    ) then "Input does not fit expected pattern" | halt_error else
      # Under these conditions, synched positions of ..Zs happen at:
      # LCM = Π(loop_size_i / GCM) * GCM

      # loop_size_i / GCM
      .[0].value[0] / $l
    end
) as $i (1; . * $i)

# Output LCM = first step where, all ghosts are on "..Z" nodes
| . * $l
