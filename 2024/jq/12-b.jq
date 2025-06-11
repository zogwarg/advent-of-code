#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

([
     inputs/ "" | to_entries
 ] | to_entries | map(
     .key as $y | .value[]
   | .key as $x | .value   | { "\([$x,$y])":[[$x,$y],.] }
)|add) as $grid | #           Get indexed grid          #

.groups = [ $grid[] | { # Start with every cell as a group to merge #
  group: [.],           # - list of cells                           #
  neigbours: [          # - list of neighbours (including out)      #
    .[0] as [$x,$y] | (
      "\([$x+1,$y])", "\([$x-1,$y])", "\([$x,$y+1])", "\([$x,$y-1])"
    ) as $k | $grid[$k] // [($k|fromjson), "out"]
  ]
}] |

until( #  Slowest Part right now, could merge faster than 1-by-1    #
  all(.groups[]; .group[0][1] as $t | all(.neigbours[]; .[1] != $t));
  debug(.groups|length)
  | .next = [
    first(
      .groups[]
      | .group[0][1] as $t
      | select(any(.neigbours[]; .[1] == $t))
    )
  ]
  | .groups = .groups - .next
  | .merge = [
    first(
      .next[0].group[0][1] as $t |
      (.next[0].neigbours[] | select(.[1] == $t)) as $n |
      .groups[] | select(any(.group[][0] == $n[0]; .))
    )
  ]
  | .groups = .groups - .merge
  | .groups = .groups + [
    {
      group: (.next[0].group + .merge[0].group),
      neigbours: (
        ((.next[0].neigbours + .merge[0].neigbours)|unique) -
          .next[0].group - .merge[0].group
      )
    }
  ]
)

| .groups
| map({
    t: .group[0][1],
    a: (.group|length),
    p: (
      (.group|map(.[0])) as $g |
      reduce(
          .neigbours[] as [[$x,$y]]    | # For each neighbour       #
          [$x+1,$y,"r"], [$x-1,$y,"l"],  # Get each inside block by #
          [$x,$y+1,"d"], [$x,$y-1,"u"] | # touched direction        #
          select(any(.[0:2] == $g[]; .))
      ) as [$x,$y,$d] ([]; #   Verbosely build the directed edges   #
        if $d == "r" or $d == "l"  then
          [first(.[]
            | select(.[0][2]==$d and  .[0][1]==$y+1 and .[0][0]==$x)
          )] as $U |
          [first(.[]
            | select(.[0][2]==$d and .[-1][1]==$y-1 and .[0][0]==$x)
          )] as $D |
          if $U[0] then . - $U end | if $D[0] then . - $D end |
          . + [ $D[0] + [[$x,$y,$d]] + $U[0] ]
        elif $d == "u" or $d == "d" then
          [first(.[]
            | select(.[0][2]==$d and  .[0][0]==$x+1 and .[0][1]==$y)
          )] as $R |
          [first(.[]
            | select(.[0][2]==$d and .[-1][0]==$x-1 and .[0][1]==$y)
          )] as $L |
          if $R[0] then . - $R end | if $L[0] then . - $L end |
          . + [ $L[0] + [[$x,$y,$d]] + $R[0] ]
        end
      ) | length
    )
  } | .s = .a * .p | debug)

# Final output:
| map(.s) | add
