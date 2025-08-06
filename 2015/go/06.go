///usr/bin/env go run $0 $@ ; exit
package main

import (
	"fmt"
	"strings"

	"github.com/zogwarg/advent-of-code/utils/go"
)

func main() {
	input := string(utils.GetInputBytes())

	screenA := make([][]bool, 1000)
	screenB := make([][]int, 1000)

	for i := range screenA {
		screenA[i] = make([]bool, 1000)
		screenB[i] = make([]int, 1000)
	}

	var action string
	var x1, y1, x2, y2 int

	for _, line := range strings.Split(input, "\n") {

		if len(line) < 3 {
			continue
		} else if line[0:3] == "tog" {
			fmt.Sscanf(line, "%s %d,%d through %d,%d", &action, &x1, &y1, &x2, &y2)
		} else if line[0:3] == "tur" {
			fmt.Sscanf(line, "turn %s %d,%d through %d,%d", &action, &x1, &y1, &x2, &y2)
		} else {
			continue
		}

		for x := x1; x <= x2; x++ {
			for y := y1; y <= y2; y++ {
				switch action {
				case "toggle":
					screenA[x][y] = !screenA[x][y]
					screenB[x][y] += 2
				case "on":
					screenA[x][y] = true
					screenB[x][y]++
				case "off":
					screenA[x][y] = false
					if screenB[x][y] > 0 {
						screenB[x][y]--
					}
				default:
					panic("Unexpected!")
				}
			}
		}
	}

	count, brightness := 0, 0
	for x := 0; x < 1000; x++ {
		for y := 0; y < 1000; y++ {
			brightness += screenB[x][y]
			if screenA[x][y] {
				count++
			}
		}
	}
	fmt.Printf("Part A: %d\n", count)
	fmt.Printf("Part B: %d\n", brightness)
}
