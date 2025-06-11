#!/bin/sh
# \
exec jq -n -crR -f "$0" "$@"

( # If solving manually input need --arg swaps
  # Expected format --arg swaps 'n01-n02,n03-n04'
  # Trigger start with --arg swaps '0-0'
  if $ARGS.named.swaps then $ARGS.named.swaps |
    split(",") | map(split("-") | {(.[0]):.[1]}, {(.[1]):.[0]}) | add
  else {} end
) as $swaps |

[ inputs | select(test("->")) / " " | del(.[3]) ] as $gates |

[ # Defining Target Adder Circuit #
  def pad: "0\(.)"[-2:];
  (
    [ "x00", "AND", "y00", "c00" ],
    [ "x00", "XOR", "y00", "z00" ],
    (
      (range(1;45)|pad) as $i |
      [ "x\($i)", "AND", "y\($i)", "c\($i)" ],
      [ "x\($i)", "XOR", "y\($i)", "a\($i)" ]
    )
  ),
  (
    ["a01", "AND", "c00", "e01"],
    ["a01", "XOR", "c00", "z01"],
    (
      (range(2;45) | [. , . -1 | pad]) as [$i,$j] |
      ["a\($i)", "AND", "s\($j)", "e\($i)"],
      ["a\($i)", "XOR", "s\($j)", "z\($i)"]
    )
  ),
  (
    (
      (range(1;44)|pad) as $i |
      ["c\($i)", "OR", "e\($i)", "s\($i)"]
    ),
    ["c44", "OR", "e44", "z45"]
  )
] as $target_circuit |

( #        Re-order xi XOR yi wires so that xi comes first        #
  $gates | map(if .[0][0:1] == "y" then  [.[2],.[1],.[0],.[3]] end)
) as $gates |

#  Find swaps, mode=0 is automatic, mode>0 is manual  #
def find_swaps($gates; $swaps; $mode): $gates as $old |
  #                   Swap output wires                #
  ( $gates | map(.[3] |= ($swaps[.] // .)) ) as $gates |

  # First level: 'x0i AND y0i -> c0i' and 'x0i XOR y0i -> a0i' #
  #      Get candidate wire dict F, with reverse dict R        #
  ( [ $gates[]
      | select(.[0][0:1] == "x" )
      | select(.[0:2] != ["x00", "XOR"] )
      | if .[1] == "AND" then { "\(.[3])": "c\(.[0][1:])"  }
      elif .[1] == "XOR" then { "\(.[3])": "a\(.[0][1:])"  }
      else "Unexpected firt level op" | halt_error end
    ] | add
  ) as $F | ($F | with_entries({key:.value,value:.key})) as $R |

  #       Replace input and output wires with candidates      #
  ( [ $gates[]  | map($F[.] // .)
      | if .[2] | test("c\\d") then [ .[2],.[1],.[0],.[3] ] end
      | if .[2] | test("a\\d") then [ .[2],.[1],.[0],.[3] ] end
    ] # Makes sure that when possible a0i comes 1st, then c0i #
  ) as $gates |

  # Second level:   use info rich 'c0i OR e0i -> s0i' gates   #
  #      Get candidate wire dict S, with reverse dict T       #
  ( [ $gates[]
      | select((.[0] | test("c\\d")) and .[1] == "OR" )
      | {"\(.[2])": "e\(.[0][1:])"}, {"\(.[3])": "s\(.[0][1:])"}
    ] | add | with_entries(select(.key[0:1] != "z"))
  ) as $S | ($S | with_entries({key:.value,value:.key})) as $T |

  ( #      Replace input and output wires with candidates     #
    [ $gates[] | map($S[.] // .) ] | sort_by(.[0][0:1]!="x",.)
  ) as $gates  | #                   Ensure "canonical" order #

  [ # Diff - our input gates only
    $gates - $target_circuit
    | .[] | [ . , map($R[.] // $T[.] // .) ]
  ] as $g |
  [ # Diff +  target circuit only
    $target_circuit - $gates
    | .[] | [ . , map($R[.] // $T[.] // .) ]
  ] as $c |

  if $mode > 0 then
    #    Manual mode print current difference    #
    debug("gates", $g[], "target_circuit", $c[]) |

    if $gates == $target_circuit then
      $swaps | keys | join(",") #   Output successful swaps  #
    else
      "Difference remaining with target circuit!" | halt_error
    end
  else
    # Automatic mode, recursion end #
    if $gates == $target_circuit then
      $swaps | keys | join(",") #   Output successful swaps  #
    else
      [
        first(
          # First case when only output wire is different
          first(
            [$g,$c|map(last)]
            | combinations
            | select(first[0:3] == last[0:3])
            | map(last)
            | select(all(.[]; test("e\\d")|not))
            | select(.[0] != .[1])
            | { (.[0]): .[1], (.[1]): .[0] }
          ),
          # "Only" case where candidate a0i and c0i are in an
          # incorrect input location.
          # Might be more than one for other inputs.
          first(
            [
              $g[] | select(
                ((.[0][0]  | test("a\\d")) and .[0][1] == "OR") or
                ((.[0][0]  | test("c\\d")) and .[0][1] == "XOR")
              ) | map(first)
            ]
            | if length != 2 then
                "More a0i-c0i swaps required" | halt_error
              end
            | map(last)
            | select(.[0] != .[1])
            | { (.[0]): .[1], (.[1]): .[0] }
          )
        )
      ] as [$pair] |
      if $pair | not then
        "Unexpected pair match failure!" | halt_error
      else
        find_swaps($old; $pair+$swaps; 0)
      end
    end
  end
;

find_swaps($gates;$swaps;$swaps|length)
