#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# A poor JQ's man bit uint16 operators
( pow(2;16) - 1 ) as $intMax |
( pow(2;15) ) as $intHalf |
def NOT: $intMax - . ;
def LSHIFT($a): significand * pow(2; logb + $a) % ($intMax + 1) ;
def RSHIFT($a): significand * pow(2; logb - $a) % ($intMax + 1) ;
def AND($a; $b):
  {d: $intHalf, r: 0, a:$a, b: $b} | until(.d == 0;
    .r = if .a >= .d and .b >= .d then .r + .d else .r end |
    .a = if .a >= .d then .a - .d else .a end |
    .b = if .b >= .d then .b - .d else .b end |
    .d |= RSHIFT(1)
  ) | .r
;
def OR($a; $b):
  {d: $intHalf, r: 0, a:$a, b: $b} | until(.d == 0;
    .r = if .a >= .d or .b >= .d then .r + .d else .r end |
    .a = if .a >= .d then .a - .d else .a end |
    .b = if .b >= .d then .b - .d else .b end |
    .d |= RSHIFT(1)
  ) | .r
;

# Gather all wires
reduce (
  inputs / " -> " | .[0] /= " " | flatten
) as $wire ({};
  def to_node($w):$w |
    if length == 2 then
      { "name": $w[-1], "values": [$w[0] | (select(test("\\d+"))) |= tonumber ]} |
      # Initialize value if possible
      if .values[0] | type == "number" then .value = .values[0] else . end
    elif length == 3 then
      { "name": $w[-1], "op": "NOT", "values": [$w[1] | (select(test("\\d+"))) |= tonumber ]}
    else
      { "name": $w[-1], "op": $w[1], "values": [($w[2], $w[0]) | (select(test("\\d+"))) |= tonumber ]}
    end
  ;
  ( to_node($wire)) as $n | .[$n.name] = ($n | del(.name))
) |
# Until all wires have set "value"
until([ .[] | has("value") ] | all;
  # Use all unsubstituted wire with "value"
  reduce (to_entries[] | select(.value | has("value") and (.s | not))) as {key: $k, value: $v} (.;
    # Operate on all wires referecing the current wire key = $k
    ( .[] | select((has("value") | not) and (.values | index($k) ) )) |= (
      .values[] |= (
        # Substitute reference with value
        if . == $k then $v.value else . end
      )
      # If all values are numbers, we can call the operator and set value
      | if [ .values[] | type == "number" ] | all then
          if .op | not then
            .value = .values[0]
          elif .op == "NOT" then
            .value = ( .values[0] | NOT )
          elif .op == "AND" then
            .value = AND(.values[0];.values[1])
          elif .op == "OR" then
            .value = OR(.values[0];.values[1])
          elif .op == "LSHIFT" then
            .value = ( .values as [$b, $a] | $a | LSHIFT($b) )
          elif .op == "RSHIFT" then
            .value = ( .values as [$b, $a] | $a | RSHIFT($b) )
          else
            .
          end
        else
          .
        end
    )
    # Mark substitution as done
    | .[$k].s = true
  )
)

# Output value on wire "a"
| .a.value
