#!/usr/bin/env bash

advent-get-input() {
  year=${1:-$(date +'%Y')}
  day=${2:-$(date +'%d' | jq)}
  curl -H "Cookie: session=$(cat session.txt)" -s https://adventofcode.com/${year}/day/${day}/input > input.txt
  printf $year > year.txt
  printf $day > day.txt
}

advent-get-description() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -H "Cookie: session=$(cat session.txt)" -s https://adventofcode.com/${year}/day/${day} \
  | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist > description.txt
}

advent-part-a() {
  cat > a.jq <<TERM
#!/usr/bin/env jq -n -R -f

[ inputs ]
TERM

  chmod +x a.jq
  subl a.jq
}

advent-part-b() {
  cp a.jq b.jq
  subl b.jq
}

advent-submit-a() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=1&answer=$(./a.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-submit-b() {
  year=$(cat year.txt)
  day=$(cat day.txt)
  curl -s https://adventofcode.com/${year}/day/${day}/answer \
    -H "Cookie: session=$(cat session.txt)" \
    -H 'content-type: application/x-www-form-urlencoded' \
    -d "level=2&answer=$(./b.jq input.txt | jq -rR '@uri')" \
    | jq -srR 'match("<main>.+</main>";"gm").string' | lynx -stdin -dump -nolist
}

advent-write-day() {
  year=$(cat year.txt)
  day=$(cat day.txt | xargs printf "%02d")
  if [[ ! $day -eq "25" ]]; then
    mv a.jq ${year}/jq/${day}-a.jq
    mv b.jq ${year}/jq/${day}-b.jq
  else
    mv a.jq ${year}/jq/${day}.jq
  fi
}
