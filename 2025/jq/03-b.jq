#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ def left_most: (.value|tonumber), -.key;
  #  Padded string with indices   #
  inputs / "" | to_entries + [{}] |

  # Get maximum left-most digit, leaving enough string to still #
  #                 Be able to get remaining ones               #
  reduce range(12) as $j ({s:., d: "", l: -1};
    ( .s[.l+1:$j-12] | max_by(left_most)) as {key: $l, value: $v}
    | .l = $l        | .d = .d + $v
  ) | .d             | tonumber
] | add
