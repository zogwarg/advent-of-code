#!/usr/bin/env jq -n -R -f

def compute: . as $n |
  def _c($acc;$i):
    # Tests
    def     op: $n[$i] == "*" or $n[$i] == "+"; # Is next operator
    def    num: $n[$i+1]  |  type == "number" ; # Is follow next num
    def  close: $n[$i]|not  or  $n[$i] == ")" ; # Does next finish _c
    #     Do the operation "*" or "+" to accumulated value        #
    def do($b): if $n[$i] == "*" then $acc * $b else $acc + $b end;

      if op and  num      then _c(do($n[$i+1]);$i+2)  #──to next
    elif op and (num|not) then _c($n[$i+2];$i+3) | _c(do(.r); .j)
    elif   close          then { r: $acc, j: ($i+1) } #─end └─fork
    else
      "Unexpected state: \({$acc,next:$n[$i]})" | halt_error
    end
  ;
  _c($n[0];1).r
;

[
    inputs                     # Normalize inputs so parser can work:
  | gsub("^\\(";"0 + (")       # If starts as '(' prepend with '0 +'
  | gsub("\\( *\\(";"( 0 + (") # If double   '(('  add middle  '0 +'
  | [ scan("\\d+|[()+*]") | tonumber? // . ]
  | compute
] | add # Output final sum of all lines
