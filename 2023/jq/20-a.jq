#!/usr/bin/env jq -n -R -f

# Parse inputs
reduce (
  inputs / " -> " | .[1] |= (. / ", ")
) as [ $mod, $to ] ({};
  .[$mod] = $to
) |

# Sanitize circuit so that all references
# Include the module type
reduce (
  del(.broadcaster) | keys[] | [ . , .[1:]]
) as [$key, $sub] (.;
  .[][] |= if . == $sub then $key end
) | . as $circuit |

# Get the default state of all conjunction modules
reduce (
  $circuit | to_entries[] | .key as $from | .value[] | select(.[0:1] == "&") | [$from, .]
) as [$from, $to] ({};
  .[$to][$from] = 0
) | . as $from |

# Iterate through 1000 button presses
last(foreach range(1000) as $_ ({lo: 0, hi: 0, on: {}, $from};
  # Init wire state update
  .wire = [["broadcaster","button",0]] |
  # Until no more wires to be processed for current button press
  until (isempty(.wire[]);
    # Dequeue wire state
    .wire[0] as [$mod, $from, $sig] | .wire |= .[1:] |

    # Accumulate updates
    ( if $sig == 0 then .lo += 1 else .hi += 1 end ) |

    if $mod == "broadcaster" then
      # Add output wires to be processed
      .wire += [ $circuit[$mod][] as $nmod | [$nmod, $mod, 0 ]]
    elif $mod[0:1] == "%" then
      # If flip-flop only do something if signal is lo
      if $sig == 0 then
        # Flip state and get output signal (lo for new state off, hi for on)
        ( .on[$mod] // 1 ) as $nsig |
        if .on[$mod] then del(.on[$mod]) else .on[$mod] = 0 end |

        # Add output wires to be processed
        .wire += [ $circuit[$mod][] as $nmod | [$nmod, $mod, $nsig ]]
      end
    elif $mod[0:1] == "&" then
      # Update last seen value for current wire
      .from[$mod][$from] = $sig |
      # Output lo if all wires were hi, otherwise output lo
      ( if all(.from[$mod][]; . == 1) then 0 else 1 end ) as $nsig |

      # Add output wires to be processed
      .wire += [ $circuit[$mod][] as $nmod | [$nmod, $mod, $nsig ]]
    elif $mod == "output" or $mod == "rx" then
      . # Do nothing for output, or for rx, who does not have any output
    else
      "Unexpected mod: \($mod)" | halt_error
    end
  )
))

| .lo * .hi
