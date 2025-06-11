#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Gaze upon these fair moons, and see their dances
[ inputs | [[scan("-?\\d+") | tonumber],[0,0,0]]]|

def tick($moons):
  reduce $moons[]   as [[$mx,$my,$mz],$mv] ([];
    . + [[[$mx,$my,$mz],$mv]] |
    reduce $moons[] as [[$nx,$ny,$nz],$nv] ( .;
      .[-1][1][0] |= if $mx>$nx then .-1 elif $mx<$nx then .+1 end |
      .[-1][1][1] |= if $my>$ny then .-1 elif $my<$ny then .+1 end |
      .[-1][1][2] |= if $mz>$nz then .-1 elif $mz<$nz then .+1 end |
      .
    ) |
    .[-1][0] = ( .[-1] | transpose | map(add) )
  )
;

def ticks($n): reduce range($n) as $_ (.;tick(.)) ;
def totenergy: [ .[] | map( map(abs) | add ) | .[0] * .[1] ] | add ;

ticks(1000) | totenergy
