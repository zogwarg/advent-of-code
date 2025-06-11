#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get uncompressed length for string
def decompress:
  # If still markers
  if index("(") then
    # Until no more markers
    {out: 0, in: ., } | until(.in | index("(") | not ;
      # Parse Marker
      .m = (.in | match("\\([^)]+\\)").string[1:-1] / "x" | map(tonumber)) |

      # If current marker is not at pos 0
      # Add length before "(" to "out"
      .out = (.out + (.in | index("("))) |

      # Flush "in"
      .in = .in[(.in | index(")") +1):] |

      # Recurvily call decompressm and add length to out
      .out = ( .out + .m[1] * ( .in[:.m[0]] | decompress) ) |

      # Flush "in"
      .in = .in[.m[0]:]
    )
    # If no more markers, add remaining length of "in" to "out"
    | .out + (.in | length)
  else
    # If no markers in current call, output is length
    length
  end
;

# Output recursively decompressed size
inputs | decompress
