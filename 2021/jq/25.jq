#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

[ inputs / "" ] | [.,.[0]|length] as [$H,$W] |

def right($step):
  reduce (
      range($W) as $j
    | range($H) as $i
    | {
        v:.[$i][$j],        # Current #
        n:.[$i][($j+1)%$W], #  Next   #
        $i,$j               # Indices #
      }
  ) as {$v,$n,$i,$j} (
    # Track step number
    []|.[$H][0] = $step;
    #    Move or copy to empty    #
    if $v == ">" and $n == "." then            # Track updates
      .[$i][$j] = "." | .[$i][($j+1)%$W] = ">" | .[$H][1] += 1
    else
      .[$i][$j] = ( .[$i][$j] // $v )
    end
  )
;

def down($step;$upd):
  reduce (
      range($W) as $j
    | range($H) as $i
    | {
        v:.[$i][$j],        # Current #
        n:.[($i+1)%$H][$j], #  Next   #
        $i,$j               # Indices #
      }
  ) as {$v,$n,$i,$j} (
    # Step num and right updates
    []|.[$H][0:2] = [$step,$upd];
    #    Move or copy to empty    #
    if $v == "v" and $n == "." then            # Track updates
      .[$i][$j] = "." | .[($i+1)%$H][$j] = "v" | .[$H][1] += 1
    else
      .[$i][$j] = ( .[$i][$j] // $v )
    end
  )
;

last(label $out | foreach range(1e9) as $step (.; debug({$step}) |
  right($step) | down($step;.[$H][1]) |
  #   Exit if no updates detected   #
  if .[$H][1]|not then break $out end
))

| .[$H][0] + 2 # First step number with no updates
