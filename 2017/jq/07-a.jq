#!/usr/bin/env jq -n -rR -f

# Get all [parent, <chlidren>* ] arrays.
[ inputs | [ scan("[a-z]+") ]]

# .parents - children => produces only stack that isn't a child
| [ .[][0] ] - [ .[][1:][] ] | .[0]
