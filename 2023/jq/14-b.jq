#!/usr/bin/env jq -n -R -f
[ inputs / "" ] as $inputs |

def oneCyle:
  # Tilt UP          = T . MAP(scan) . T
  # Rotate           = T . MAP(reverse)
  # Titl UP . Rotate = T . MAP(scan) . Map(reverse) | T . T = Identity
  def tilt_up_rotate:
      transpose
    | map(("#" + add)|[ scan("#[^#]*") | ["#", scan("O"), scan("\\.")] ]| add[1:])
    | map(reverse)
  ;
  # Tilt   North,            West,           South,            East
  tilt_up_rotate | tilt_up_rotate | tilt_up_rotate | tilt_up_rotate
;

# Def utility function, for reshaping "condensed" state
def group_of($n): . as $in | [ range(0;length;$n) | $in[.:(.+$n)]];

{
  s: ($inputs),                # .s = Current state
  l: ($inputs|[map(add)|add]), # .l = List of encountered "condensed" states
  c: 0,                        # .c = Counter for current position
  i: null                      # .i = Index of first state encountered twice
} |

until(.i; .c += 1 |                           # Until loop detected:
  .s |= oneCyle | (.s|map(add)|add) as $state # Update state
                                              #
  | .i = (.l|index($state))                   # Was state seen before?
  | .l += [$state]                            # Append state to .l
)

# Get loop size
| ( .c - .i ) as $loop
# Get idx for state after 1 billion cycles, withtin .l
| ( .i + (( 1000000000 - .i ) % $loop )) as $billionth_idx

# Reshape billionth state
| .l[$billionth_idx] / "" | group_of($inputs[0]|length)

# For each row, count  'O'  rocks
| map(add | [scan("O")] | length)

# Add total load on "N" beam
| [0] + reverse | to_entries
| map( .key * .value ) | add
