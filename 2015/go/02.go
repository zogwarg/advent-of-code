///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"sort"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	input := string(utils.GetInputBytes())
	var paper, bow int
	for _, line := range strings.Split(input, "\n") {
		var a, b, c int
		fmt.Sscanf(line, "%dx%dx%d", &a, &b, &c)
		dims := []int{a, b, c}
		sort.Ints(dims)
		l, w, h := dims[0], dims[1], dims[2]
		paper += 3*l*w + 2*(w*h+h*l)
		bow += 2*(l+w) + l*w*h
	}
	fmt.Printf("Part A: %d\n", paper)
	fmt.Printf("Part B: %d\n", bow)
}
