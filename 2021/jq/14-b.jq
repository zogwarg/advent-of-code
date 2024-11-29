#!/usr/bin/env jq -n -sR -f

inputs | rtrimstr("\n") / "\n\n"

| (.[0][1:-1]/"") as $middle
| ( .[1] / "\n" | map([scan("\\w+")] | {(.[0]): .[1]} ) | add) as $R |

# Aggregate stream of objects summing their values
def aggregate(obj): reduce (obj|to_entries[]) as {$key,$value} ({};
  .[$key] += $value
);

(
  reduce range(40) as $i (
    # Initial contribution of letter pairs at 0, {AB:{A:1,B:1}}
    $R|with_entries(
      .value = ([.key|{(scan("\\w")):1}]|add)
      | if .value|length == 1 then .value[] |= 2 end
    );
    . as $prev | with_entries(           # With rule AB -> X   #
      .value = aggregate(                #                     #
        $prev["\(.key[:1] + $R[.key])"], # prev(AX) + prev(XB) #
        $prev["\($R[.key] + .key[1:])"]  #     .[X] -= 1       #
      )
      | .value[$R[.key]] -= 1
    )
  )
) as $P # Contribution of elements for each rule pair.

#              Zip accross our input string                 #
| aggregate(.[0]| range(length) as $i | $P[.[$i:$i+2]] // {})
#  Middle letters overlap   #   Final Output   #
| .[$middle[]] -= 1 | debug | map(.) | max - min
