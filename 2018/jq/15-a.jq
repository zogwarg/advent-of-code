#!/usr/bin/env jq -n -rR -f

# Parsing field
[ inputs   / ""     ] as $grid |
( $grid    | length ) as $H    |
( $grid[0] | length ) as $W    |

[ # Get mapping mapping (y, x) => value
  $grid
  | to_entries[] | .key as $j | .valueg
  | to_entries[] | .key as $i
  | [[$j,$i], .value]
] |

{ # Initialize field state and units
  units: map(select(.[1] | inside("GE")) | .[2] = 200),
  field: map({"\(.[0])": .[1]}) | add,
  turn_idx: 0
} |

# Default movemment
[[-1,0], [0,-1], [0, 1], [1, 0]] as $dydx |

# Debug function
def print_field:
 (
  (
    reduce (
      .units
      | group_by(.[0][0])
      | map([ .[0][0][0], (map("\(.[1])(\(.[2]))") | "   " + join(", "))])
      | .[]
    ) as $r ([]; .[$r[0]] = $r[1] )
  ) as $units |
  [
    .field
    | to_entries[]
    | .key |= fromjson
  ] | group_by(.key[0])
    | map( .[0].key[0] as $y | (map(.value) | add + $units[$y] | debug ))
  ) as $d | .
;

# Until one side has won
until (([ .units[][1] ] | unique | length == 1 );
  def move_unit:
    (
      { # Search closest opponent
        field,
        search:   [.units[.turn_idx][0]],
        unit_type: .units[.turn_idx][1],
        seen: {"\( .units[.turn_idx][0])": "\(.units[.turn_idx][0])"}
      }
      | until (isempty(.search[]) or .found;
        .unit_type as $t |
        .field as $f |
        .seen as $seen |
        ( .search[0] ) as $s | .search = .search[1:] |
        ([
          $dydx[] as [$dy, $dx]
          | $s | .[0] += $dy | .[1] += $dx
          | select(
            ($seen["\(.)"] | not) and
            $f["\(.)"] != "#"     and
            $f["\(.)"] != $t
          )
        ]) as $next | reduce $next[] as $n (.;
          if $f["\($n)"] != "." then
            .found = $s
          else
            .seen["\($n)"] = "\($s)" |
            .search += [ $n ]
          end
        )
      ) # Coordinates of opponent found, or stay in place
      | "\(.found // (.seen | keys_unsorted[0]))" as $f
      | if .seen[$f] == $f then
          $f | fromjson
        else
          # Find coordinatez of first step to oppopent
          last([ $f, .seen ] | recurse(
            if .[1][.[0]] == .[0] or .[1][.[1][.[0]]] == .[1][.[0]] then
              empty
            else
              [.[1][.[0]], .[1] ]
            end
          )) | .[0] | fromjson
        end
    ) as $n |
    # Update field and units
    .field["\(.units[.turn_idx][0])"] = "." |
    .units[.turn_idx][0] = $n |
    .field["\($n)"] = .units[.turn_idx][1]
  ;
  def unit_atk:
    ( .units[.turn_idx] // empty ) as $u | # Current unit
    ( # Opponent units
      .units
      | to_entries
      | map(select(.value[1] != $u[1] ) | {key: "\(.value[0])", value: .key} )
      | from_entries
    ) as $opp_units |
    [ # Indices of opponents in range
      $u[0] | $dydx[] as [$dy, $dx] | .[0] += $dy | .[1] += $dx
            | $opp_units["\(.)"] | numbers
    ] as $i |
    if isempty($i[]) then . else
      # Attack most weakened opponent
      ([ $i[] as $i |  [ .units[$i], $i ] ] | min_by(.[0][2])[1]) as $i |
      .units[$i][2] -= 3 |
      # Remove unit if it dies
      if .units[$i][2] <= 0 then
        .field["\(.units[$i][0])"] = "." |
        .units = .units[:$i] + .units[$i+1:] |
        .death = $i
      end
    end
  ;
  # Do battle
  .i += 1 | debug({i}) |
  until (.units[.turn_idx] | not;
    move_unit |
    unit_atk  |
    if ( .death | not ) or .death > .turn_idx then
      .turn_idx += 1
    end | del(.death)
  )
  | .turn_idx = 0
  | .units |= sort_by(.[0])
  | print_field
)

# Calculate combat outcome
| ( .i - 1 ) * ( .units | map(.[2]) | add)
