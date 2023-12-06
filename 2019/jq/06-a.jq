#!/usr/bin/env jq -n -R -f

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

# Recursively add depth info + total depth sum
| reduce ([ paths(. == {} ) | .[0:range(1;length+1)] | select(length > 1) ] | unique[]) as $path (.;
  ( getpath($path[:-1]).d + 1 ) as $d |
    getpath($path).d = $d |
  .s += $d
)

# Output total depth sum = direct orbits + indirect orbits
| .s
