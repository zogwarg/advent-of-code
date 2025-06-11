#!/bin/sh
# \
exec jq -n -f "$0" "$@"

reduce (
  # ┌─ Outlet                    # Compare each successive adapter
  # ▼  ▼─Adapters    Laptop─▼    # And count the gaps of: 1 or 3
  [ 0, inputs ] | sort + [max+3] | range(1;length) as $i | .[$i-1:$i+1]
) as [$a, $b] ({i:0,iii:0}; if $b-$a == 1 then .i+=1 else .iii+= 1 end)
# Output Result
| .i * .iii
