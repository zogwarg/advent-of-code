#!/usr/bin/env jq -n -sR -f

reduce (
  inputs | rtrimstr("\n") / "\n\n" | .[] | split("\n")
) as $c ({keys:[],locks:[],fit: 0};
  def fit(cat; other):
    ( $c
      | map(split(""))
      | transpose
      | map(add| scan("#+") | length - 1) # Get column '#' length #
    ) as $c | cat += [$c] | # Add key or lock to correct category #
    reduce ( # With how many in other category, do all cols fit ? #
      other | [.,$c] | transpose | map(add) | select(all(.[];. < 6))
    ) as $k (.; .fit = .fit + 1 )
  ;
  if $c[0] == "#####" then fit(.locks; .keys[])
                      else fit(.keys; .locks[]) end
) | .fit
