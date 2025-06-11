#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce( inputs |
  [ # Get each [on, bounding box] line
    { on:1, off: -1}[ scan("on|off") ],
    [    scan("-?\\d+")|tonumber     ]
  ] |       .[1][1,3,5] += 1
    # Excluding mode for upper bound #
) as [$s,$xyz] ({};

  reduce (.[]
    | (.n * -1) as $n
    | [.xyz,$xyz] as [
        [$ax1,$ax2,$ay1,$ay2,$az1,$az2],
        [$sx1,$sx2,$sy1,$sy2,$sz1,$sz2]
      ]
    | select (
        $sx1 < $ax2 and $sx2 > $ax1 and
        $sy1 < $ay2 and $sy2 > $ay1 and
        $sz1 < $az2 and $sz2 > $az1
      )
    | [
        [$sx1,$sx2,$ax1,$ax2],
        [$sy1,$sy2,$ay1,$ay2],
        [$sz1,$sz2,$az1,$az2]
        | sort[1:3]
      ]
    | [$n, add ]
    #     Get each intersection box    #
  ) as [$s,$xyz] (
    # Start with main-line=on #
    if $s == 1 then
        .["\($xyz)"].s  += [$s]
      | .["\($xyz)"].xyz = $xyz
    end;
    # Get all flips to a given bounding box region #
    .["\($xyz)"].s += [$s] | .["\($xyz)"].xyz = $xyz
  )

  | map_values(
      # Merge all intersections and only keep the  #
      # Boxes in on state                          #
      .n = .n + (.s|add) | select(.n != 0) | .s = []
    )
)

| map(.n * ( .xyz | (.[5]-.[4]) * (.[3]-.[2]) * (.[1]-.[0]) ) ) | add
