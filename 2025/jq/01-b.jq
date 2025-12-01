#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce (
  inputs | [ scan("[LR]"), (scan("\\d+") | tonumber) ]
) as [$D, $V] (
  { # Directions  # Clicks #    Mirror Helper    #
    L: 50, R: 50, z: 0,    rev: { L: "R", R: "L" }
  };
    .[$D] = ( .[$D] + $V )               #   main    dial  #
  | .z = .z + ( .[$D] / 100 | floor )    # multiple clicks #
  | .[$D] = .[$D] % 100                  #   main   modulo #
  | .[.rev[$D]] = ( 100 - .[$D] ) % 100  #  mirror   dial  #
) | .z
