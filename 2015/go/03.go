///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"github.com/zogwarg/advent-of-code/utils/go"
)

type pos struct {
	x int
	y int
}

func main() {
	curr, santa, robot := pos{0, 0}, pos{0, 0}, pos{0, 0}
	visitsA, visitsB := make(map[pos]bool), make(map[pos]bool)
	visitsA[pos{0, 0}], visitsB[pos{0, 0}] = true, true

	actor := &santa

	for _, dir := range utils.GetInputBytes() {
		switch dir {
		case '^':
			curr.y += 1
			actor.y += 1
		case 'v':
			curr.y -= 1
			actor.y -= 1
		case '>':
			curr.x += 1
			actor.x += 1
		case '<':
			curr.x -= 1
			actor.x -= 1
		}

		visitsA[curr], visitsB[*actor] = true, true

		if actor == &santa {
			actor = &robot
		} else {
			actor = &santa
		}
	}

	fmt.Printf("Part A: %d\n", len(visitsA))
	fmt.Printf("Part B: %d\n", len(visitsB))
}
