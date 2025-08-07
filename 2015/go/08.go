///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	input := string(utils.GetInputBytes())

	var delta_unescape, delta_escape int

	for _, line := range strings.Split(input, "\n") {
		if len(line) < 2 {
			continue
		}

		// Opening quotes contribution
		delta_unescape += 2
		delta_escape += 4

		esc := false
		for _, char := range line[1 : len(line)-1] {
			switch char {
			case '"':
				delta_escape += 1
				delta_unescape -= 2
				esc = false
			case '\\':
				delta_escape += 1
				if esc {
					delta_unescape -= 2
					esc = false
				} else {
					delta_unescape += 3
					esc = true
				}
			default:
				esc = false
			}
		}
	}

	fmt.Printf("Part A: %d\n", delta_unescape)
	fmt.Printf("Part B: %d\n", delta_escape)
}
