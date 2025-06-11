#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Get our availables towels and our list of desired patterns  #
[ inputs ] | [ (.[0] / ", "), .[2:] ] as [$towels, $patterns] |

reduce $patterns[] as $p (0;
  # Check if pattern is possible  #
  # recursively using memoisation #
  def possible($pattern; $memo):
    (
      { possible: $memo[$pattern], $memo}
      | select(.possible|type=="boolean")
    ) // (
      reduce $towels[] as $t ({possible: false, $memo};
        if $pattern|startswith($t) then
          possible(
            $pattern[$t|length:];
            .memo
          ) as { possible: $y, memo: $m }
          | .possible = ( .possible or $y )
          | .memo += $m
        end
      )
    ) | .memo[$pattern] = .possible
  ; possible($p; {"": true}) as {$possible}

  | if $possible then . + 1 end
)
