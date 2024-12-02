#!/usr/bin/env jq -n -R -f

[
  inputs | [scan("\\d+")|tonumber]
  | select(
      any(
        range(length) as $i | del(.[$i]) # Any consecutive pairs  #
        | [ .[0:-1], .[1:] ]             # list with one element  #
        | transpose ;                    #        removed         #
        all(.[]; first - last | . > 0 and . < 4) or # Descending  #
        all(.[]; last - first | . > 0 and . < 4)    #  Ascending  #
      )
    )
] | length
