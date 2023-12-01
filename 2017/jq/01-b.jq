#!/usr/bin/env jq -n -R -f
[
  # Get list of digits
  inputs / "" |

  # Offset by length/2 and transpose
  [. , .[length/2:] + .[0:length/2] ] | transpose[] |

  # Only return tonumber if number length/2 away is same
  if .[0] == .[1] then .[0] | tonumber else 0 end
] |

# Return sum
add
