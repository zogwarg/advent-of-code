#!/bin/sh
# \
exec jq -n -f "$0" "$@"

# The Jospehus problem, elf edition
# If there are   N  = 2^a + l players
#         then W(N) = 2*l + 1

inputs | 2 * ( . - pow(2;logb) ) + 1
