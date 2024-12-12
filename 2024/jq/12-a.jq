#!/usr/bin/env jq -n -R -f

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
| map(
    {
      t: .group[0][1],
      a: (.group|length),             # Area                       #
      p: (
        (.group|map(.[0])) as $g |
        reduce (
          .neigbours[] as [[$x,$y]] | # Count contribution of each #
          [$x+1,$y], [$x-1,$y],       # Neighbour to the perimeter #
          [$x,$y+1], [$x,$y-1]      | # +1 for each adjacent group #
          select(any(. == $g[]; .))   # member                     #
        ) as $n (0; . + 1)
      )
    } | .s = .a * .p | debug
  )

# Final output:
| map(.s) | add
