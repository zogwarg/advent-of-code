#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get our availables towels and our list of desired patterns  #
[ inputs ] | [ (.[0] / ", "), .[2:] ] as [$towels, $patterns] |

reduce $patterns[] as $p (0;
  # Count possible pattern combos #
  # recursively using memoisation #
  def count($pattern; $memo):
    (
      { count: $memo[$pattern], $memo }
      | select(.count)
    ) // (
      reduce $towels[] as $t ({count: 0, $memo};
        if $pattern|startswith($t) then
          count(
            $pattern[$t|length:];
            .memo
          ) as { count: $c, memo: $m }
          | .count += $c
          | .memo  += $m
        end
      )
    ) | .memo[$pattern] = .count
  ; . + count($p; {"": 1}).count
)