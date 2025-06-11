#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

last(
  foreach range(1000) as $_ (
    { # Init
      particles: [
        inputs
        | [ scan("-?\\d+") | tonumber ]
        | { p:.[0:3], v:.[3:6], a:.[6:] }
      ]
    };

    # Update particles
    .particles = ( .particles | [
      .[] |
      .v = ([.v,.a] | transpose | map(.[0] + .[1])) |
      .p = ([.p,.v] | transpose | map(.[0] + .[1]))
    ] | group_by(.p)
      | map(if length > 1 then empty else .[] end)
    );

    # Extract number of particles
    .particles | length
  )
)
