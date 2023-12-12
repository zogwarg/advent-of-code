# Advent-of-code

My completion of the advent of code challenge, using jq (and maybe other languages in the future).
Started in 2023, but trying to implement past years as well.

```bash
# For a given day input.txt you can run the script directly,
# and the script will output the answer to stdout
./2023/jq/01-a.jq input.txt

# For convience bash functions are added

advent-get-input # By default gets current day input to input.txt for 2023
advent-get-input 2021 # Gets current day for year in the past
advent-get-input 2021 1 # Gets input for a specific day, of a past year.

advent-get-description # Outputs the description, for last downloaded input.txt

advent-part-a # Creates a clean a.jq file
advent-part-b # Copies a.jq to b.jq, to start working on part 2

advent-submit-a # Runs ./a.jq input.txt script, and submits answet to AoC
advent-submit-b # Runs ./b.jq input.txt script, and submits answet to AoC

advent-write-day # Once day is complete, copies a.jq and b.jq to correct location.
```
