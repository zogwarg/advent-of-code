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
# Also adding rx (launch module type)
reduce (
  $circuit | to_entries[] | .key as $from | .value[]
  | select(.[0:1] == "&" or . == "rx") | [$from, .]
) as [$from, $to] ({};
  .[$to][$from] = 0
) | . as $from |

# Expecting someting like ... -> &x, &y, &z -> &conj_rx -> rx
# With &x, &y, &z having a single output
( [ $circuit | to_entries[] | select(.value == ["rx"]).key ])              as $conj_rx  |
( [ $circuit | to_entries[] | select(any(.value[]==$conj_rx[]; .)).key ] ) as $conj2_rx |

(
  if $conj_rx | length != 1 or $conj_rx[0][0:1] != "&" then
    "Unexpected inputs to rx \($conj_rx)"
  end
) |
(
  if any($conj2_rx[][0:1]; . != "&") or any($from[$conj2_rx[]]; length != 1) then
    "Unexpected inputs to conj_rx \($conj2_rx)"
  end
) |

last(label $out | foreach range(1;50000) as $i ({lo: 0, hi: 0, on: {}, $from, lo_at: {}};
  # Init wire state update
  .wire = [["broadcaster","button",0]] |
  # Until no more wires to be processed for current button press
  until (isempty(.wire[]);
    # Dequeue wire state
    .wire[0] as [$mod, $from, $sig] | .wire |= .[1:] |

    # Accumulate updates + keep track of cycles for conj2_rx
    (
      if $sig == 0 then
        .lo += 1 |
        # Keeping track of which button press each conj2_rx receive its first lo signal
        # Which should be the cycle length for each,
        # They will all send hi to conj_rx when the cycles match
        # Which should be on the LCM of the cycles
        if [$mod] | inside($conj2_rx) then
          .lo_at[$mod] += [$i]
        end
      else
        .hi += 1
      end
    ) |

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
  ) |

  # Break out if all cycles detected, breaking out too early misses last entry
  ( if .break then break $out else . end ) |
  if (.lo_at | keys | length == 4) and all(.lo_at[]; length >= 2) then
    .break = true
  else
    .
  end
)) |

# Output
if (.break|not) then
  "Failed to detect cycles, try running longer" | halt_error
elif any(.lo_at[]; .[1] != 2 * .[0]) then
  "Assumptions about cycles for conj2_rx modules are not met" | halt_error
else
  def GCD($a; $b): if $b == 0 then $a else GCD($b; $a % $b) end;
  def LCM($a; $b): $a / GCD($a;$b) * $b;
  def LCM($args):
    if ($args|length) == 2 then LCM($args[0];$args[1])
    else LCM($args[0]; LCM($args[1:])) end
  ;
  # RX receives its first low at LCM of cycles
  LCM([.lo_at[][0]])
end
