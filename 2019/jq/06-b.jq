#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

# Build orbit tree, using pairs in random order
reduce (inputs / ")") as [$parent, $child] (
  [];
  ([ paths | first(select(.[-1] == $parent)) ]) as $path_parent |
  ([ paths | first(select(.[-1] == $child)) ]) as $path_child |
  if $path_child == [] then
    if $path_parent == [] then
      . += [{$parent:{$child:{}}}]
    else
      getpath($path_parent[0]) |= ( . + {$child:{}} )
    end
  else
    if $path_parent == [] then
      getpath($path_child[0][:-1]) |= {$parent:{$child:.[$child]}}
    else
      getpath($path_parent[0]) as $p |
      getpath($path_parent[0]) = ( $p + {$child:getpath($path_child[0])} ) |
      del(.[$path_child[0][0]])
    end
  end
) | .[0]

# Get total orbits to sun for ME and SANTA
| [ paths | select(.[-1] == "YOU" or .[-1] == "SAN") | .[:-1] ]

# Add distances to nearest ancestor
| ( .[0] - .[1] | length) + ( .[1] - .[0] | length)
