#!/usr/bin/env jq -n -R -f

[ inputs / "" ]   as $grid | # Parsing inputs to grid

# Small speed up use pre-transformed grids for
# Search in each direction
( $grid | map(add))                   as $rgrid |
( $grid | map(reverse|add))           as $lgrid |
( $grid | transpose|map(add))         as $tgrid |
( $grid | transpose|map(reverse|add)) as $bgrid |

($grid   |length) as $h    | # Height of grid
($grid[0]|length) as $w    | # Width  of grid

reduce ( # Starting from evert point outside the border pointing in:
  (range($h) | {x:-1, y: ., dx: 1, dy: 0}, {x:$w, y: ., dx:-1, dy: 0}),
  (range($w) | {x: ., y:-1, dx: 0, dy: 1}, {x: ., y:$h, dx: 0, dy:-1})
  | debug("From point: \([.x, .y])")
) as $beam (0;
  [
    ., # <-- Current maximum energy level
    (  # v-- Getting energy level for each starting beam.
      {beams: [$beam]} | until (.beams == []; .beams[0] as {$x,$y,$dx,$dy} | del(.beams[0]) |

        # Like for part 1, let beem vanish if it falls
        # outside the grid, or if already done
        if ( $x + $dx ) < 0 or ( $x + $dx ) >= $w or
           ( $y + $dy ) < 0 or ( $y + $dy ) >= $h or
           ( .done[[$x,$y,$dx,$dy]|join(",") ] )
        then .

        # Contrary to part 1, optimized so that instead of stepping once, we find the
        # next "stopping" block, and shoot straight to it, marking all squares in-between
        # as energized in one step

        # ⮕
        elif $dx == 1 then
          ($rgrid[$y][$x+1:]|match("[|\\\\/]|.$")) as {offset:$stop, string: $square} |
          .energized += [ range($x; $x+$stop+2) as $xi | [$xi,$y] ] |
          if $square == "|" then
            .beams += [{x: ($x+$stop+1), y: $y, dx: 0, dy: (1,-1)}] # ⬍ Two new beams
          elif $square == "\\" then                                 #
            .beams += [{x: ($x+$stop+1), y: $y, dx: 0, dy:    1  }] # ⬇ Reflection
          elif $square == "/" then                                  #
            .beams += [{x: ($x+$stop+1), y: $y, dx: 0, dy:   -1  }] # ⬆ Reflection
          end
        # ⬅
        elif $dx == -1 then
          ($lgrid[$y][$w-$x:]|match("[|\\\\/]|.$")) as {offset:$stop, string: $square} |
          .energized += [ range($x-$stop-1;$x+1) as $xi | [$xi,$y]] |
          if $square == "|" then
            .beams += [{x: ($x-$stop-1), y: $y, dx: 0, dy: (1,-1)}] # ⬍ Two new beams
          elif $square == "\\" then                                 #
            .beams += [{x: ($x-$stop-1), y: $y, dx: 0, dy:   -1  }] # ⬆ Reflection
          elif $square == "/" then                                  #
            .beams += [{x: ($x-$stop-1), y: $y, dx: 0, dy:    1  }] # ⬇ Reflection
          end
        # ⬇
        elif $dy == 1 then
          ($tgrid[$x][$y+1:]|match("[\\-\\\\/]|.$")) as {offset:$stop, string: $square} |
          .energized += [ range($y; $y+$stop+2) as $yi | [$x,$yi] ] |
          if $square == "-" then
            .beams += [{x: $x, y: ($y+$stop+1), dx: (1,-1), dy: 0}] # ⬌ Two new beams
          elif $square == "\\" then                                 #
            .beams += [{x: $x, y: ($y+$stop+1), dx:    1  , dy: 0}] # ⮕ Reflection
          elif $square == "/" then                                  #
            .beams += [{x: $x, y: ($y+$stop+1), dx:   -1. , dy: 0}] # ⬅ Reflection
          end
        # ⬆
        elif $dy == -1 then
          ($bgrid[$x][$h-$y:]|match("[\\-\\\\/]|.$")) as {offset:$stop, string: $square} |
          .energized += [ range($y-$stop-1;$y+1) as $yi | [$x,$yi]] |
          if $square == "-" then
            .beams += [{x: $x, y: ($y-$stop-1), dx: (1,-1), dy: 0}] # ⬌ Two new beams
          elif $square == "\\" then                                 #
            .beams += [{x: $x, y: ($y-$stop-1), dx:   -1  , dy: 0}] # ⬅ Reflection
          elif $square == "/" then                                  #
            .beams += [{x: $x, y: ($y-$stop-1), dx:    1  , dy: 0}] # ⮕ Reflection
          end
        end

        # Mark beam as done
        | .done[ [$x,$y,$dx,$dy]|join(",") ] = true

        # Return number of energized squares (starting point does not count)
      ) | .energized | unique | length - 1
    )
  ] | max # Keep max of (current_max, current_energized_squares)
)
