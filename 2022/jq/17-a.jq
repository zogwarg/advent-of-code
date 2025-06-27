#!/bin/sh
# \
exec jq -n -R -f "$0" "$@"

reduce range(2022) as $r (
  { # Init #
    stream: ( inputs/ "" ), #   Input stream of <> directions  #
    t_col:  ( [ range(7) as $x | { "\([$x,1])": true } ] | add ),
    l_col: {}, # Our collision maps which will be shifted by 1 #
    r_col: {}, #            in each direction                  #
    y_max: 0,  # <- The current height of the stack            #
    i: 0
  } | .l = (.stream|length) ;

  #  New rock generator  #
  def new_rock($n;$y_max): $y_max as $y |
    if $n % 5 == 0 then
      reduce range(4) as $x ({}; .["\([($x + 2),($y + 4)])"] = true )
    elif $n % 5 == 1 then
      {
                             "\([3,$y+6])": true,
        "\([2,$y+5])": true, "\([3,$y+5])": true, "\([4,$y+5])": true,
                             "\([3,$y+4])": true
      }
    elif $n % 5 == 2 then
      {
                                                  "\([4,$y+6])": true,
                                                  "\([4,$y+5])": true,
        "\([2,$y+4])": true, "\([3,$y+4])": true, "\([4,$y+4])": true,
      }
    elif $n % 5 == 3 then
      reduce range(4) as $z ({}; .["\([2,($y + 4 + $z)])"] = true)
    elif $n % 5 == 4 then
      {
        "\([2,$y+5])": true, "\([3,$y+5])": true,
        "\([2,$y+4])": true, "\([3,$y+4])": true
      }
    end
  ;

  # Move until collide #
  def move_x($rock; $c):
    if $c == ">" then
      if all($rock | keys[] | fromjson | first; . < 6) and (
        any(.l_col[$rock|keys[]];.) | not
      )
      then
        .rock = ( $rock | with_entries(
          .key = "\(.key|fromjson|.[0]=.[0]+1)"
        ))
      end
    else
      if all($rock | keys[] | fromjson | first; . > 0) and (
        any(.r_col[$rock|keys[]];.) | not
      )
      then
        .rock = ( $rock | with_entries(
          .key = "\(.key|fromjson|.[0]=.[0]-1)"
        ))
      end
    end
  ;

  # Drop to floor #
  def drop($rock) :
    if any(.t_col[$rock|keys[]];.) then
      reduce ($rock|keys[]|fromjson) as $xy (. ;
        def within: select(.[0]|.>=0 and . < 7);
        .t_col["\($xy|.[1] = .[1] + 1)"] = true |
        .l_col["\($xy|.[0] = .[0] - 1 | within)"] = true |
        .r_col["\($xy|.[0] = .[0] + 1 | within)"] = true
      )
      | .rock = false # Rock is dropped,  update stack height #
      | .y_max = ([ .y_max, ($rock|keys[]|fromjson[1])] | max )
    else
      .rock = ( $rock | with_entries(
        .key = "\(.key|fromjson|.[1]=.[1]-1)"
      ))
    end
  ;
  .rock = new_rock($r;.y_max)
  | until(.rock|not;
      move_x(.rock; .stream[.i%.l])
      | drop(.rock)
      | .i = .i + 1
    )
)

| debug(
    reduce (
      (.t_col|keys[]|fromjson | .[1] = .[1] - 1),
      (.rock|objects|keys[]|fromjson)
    ) as [$x,$y] ([];
      if .[$y] | not then .[$y] = [ range(7) | " " ] end
      | .[$y][$x] = "#"
    ) | "-------", ( reverse[] |  add? // "       " )
  )
| .y_max