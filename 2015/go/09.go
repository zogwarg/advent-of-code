///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

func visit(dists map[string]map[string]int, prev string, remaining []string, l int) (min, max int) {
	if len(remaining) == 0 {
		return l, l
	}

	min, max = 1e12, 0

	for i, v := range remaining {
		rem := append(make([]string, 0), remaining[0:i]...)
		rem = append(rem, remaining[i+1:]...)
		n, x := visit(dists, v, rem, l+dists[prev][v])
		if n < min {
			min = n
		}
		if x > max {
			max = x
		}
	}

	return
}

func main() {
	input := string(utils.GetInputBytes())
	dists := make(map[string]map[string]int)

	for _, line := range strings.Split(input, "\n") {
		items := strings.Split(line, " ")
		if len(items) != 5 {
			continue
		}
		if d, err := strconv.Atoi(items[4]); err == nil {
			a, b := items[0], items[2]
			if _, ok := dists[a]; !ok {
				dists[a] = make(map[string]int)
			}
			if _, ok := dists[b]; !ok {
				dists[b] = make(map[string]int)
			}
			dists[a][b], dists[b][a] = d, d
		}
	}

	if len(dists) > 10 {
		panic("Too many locations for bruteforcing!")
	}

	var places []string
	for k, _ := range dists {
		places = append(places, k)
	}

	min, max := visit(dists, "", places, 0)

	fmt.Printf("Part A: %d\n", min)
	fmt.Printf("Part B: %d\n", max)
}
