#!/usr/bin/env jq -n -R -f

[
  inputs | [scan("\\d+")|tonumber]
  | [ .[0:-1], .[1:] ] #            Get consecutive            #
  | transpose          #               pairs list              #
  | select(
      all(.[]; first - last | . > 0 and . < 4) or # Descending #
      all(.[]; last - first | . > 0 and . < 4)    # Ascending  #
    )
] | length
