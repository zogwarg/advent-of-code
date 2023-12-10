#!/usr/bin/env jq -n -R -f

def repeat($n;$s): [ range($n) as $i | $s ] | add;

# Decompress input
# Go through in until no more markers
{in: inputs, m: true, out: ""} | until(.m | not;
  # Match marker
  .m = ( .in | [match("\\([^)]+\\)")][0] ) |
  .m as {offset: $i, string: $s, length: $l} |

  if ( $i // 0 ) > 0 then
    # If current marker is not at pos 0
    # First output content before marker
    .out += .in[0:$i] |
    # Flush "in"
    .in |= .[$i:]
  elif ( $s // "" ) | length > 0 then
    # Parse marker
    ($s[1:-1] / "x" | map(tonumber)) as [$chars, $repeat] |

    # Append repeated substring to "out"
    .out = .out + repeat($repeat; .in[$l:$l+$chars]) |
    # Flush "in"
    .in |= .[$l+$chars:]
  else
    # If no more markers, output rest of "in" to "out"
    .out = .out + .in
  end
) | .out

# Output decompressed size
| length
