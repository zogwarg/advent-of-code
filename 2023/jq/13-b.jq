#!/bin/sh
# \
exec jq -n -sR -f "$0" "$@"

reduce (
  inputs / "\n\n" | map([scan(".+")]) | .[] | map(. / "")
) as $s ({x:0,y:0};

  # Find first vertical line that could be a mirror.
  first(
    ( $s[0] | length as $w | to_entries[1:][].key as $i | # Get each $i to test
    ( 2 * $i - $w | if . > 0 then . else 0 end )  as $o | # Offset $o if i >w/2
    # Compare all  strings,  before "|" after.reversed() to see if mirror image
    [ $s[][$o:] | (.[0:$i-$o]|join("")) == (.[$i-$o:2*$i-$o]|reverse|join(""))]
    | select(all) # Only keep ids where all rows have matching columns  ..b|b..
    | $i ), 0     # Return first(idx), or 0
  ) as $ox |

  ($s|transpose) as $s | # Transpose for convenience

  # Find first horizontal line that could be a mirror.
  first(
    ( $s[0] | length as $h | to_entries[1:][].key as $j | # Get each $j to test
    ( 2 * $j - $h | if . > 0 then . else 0 end )  as $o | # Offset $o if j >h/2
    [ $s[][$o:] | (.[0:$j-$o]|join("")) == (.[$j-$o:2*$j-$o]|reverse|join(""))]
    | select(all) # Only keep ids where all columns have matching rows ÷÷÷÷÷÷÷÷
    | $j ), 0     # Return first(idx), or 0
  ) as $oy |

  ($s|transpose) as $s | # Transpose back

  first(
    ($s|length) as $h | ($s[0]|length) as $w |
    range(0;$w) as $x |  range(0; $h)  as $y |

    # Test every mirror pattern with one smudge change
    ( $s | .[$y][$x] |= ({"#":".",".":"#"}[.])) as $s |

    first(
      ( range(1;$w) as $i | select($i != $ox) | # Exclude original X
      ( 2 * $i - $w | if . > 0 then . else 0 end ) as $o |
      [ $s[][$o:] | (.[0:$i-$o]|join("")) == (.[$i-$o:2*$i-$o]|reverse|join(""))]
      | select(all)
      | $i ), 0
    ) as $x |

    ($s|transpose) as $s |

    first(
      ( range(1;$h) as $j | select($j != $oy) | # Exclude original Y
      ( 2 * $j - $h | if . > 0 then . else 0 end )  as $o |
      [ $s[][$o:] | (.[0:$j-$o]|join("")) == (.[$j-$o:2*$j-$o]|reverse|join(""))]
      | select(all)
      | $j ), 0
    ) as $y |

    select($x > 0 or $y > 0) | {$x,$y}
    # Save first different non-zero x or y mirror line
  ) as $new | .x += $new.x | .y += $new.y

  # Output new sum
) | .y * 100 + .x
