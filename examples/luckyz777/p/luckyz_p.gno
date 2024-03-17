package luckyz_p

import (
	"math/rand"
	"time"
)

// Generate 5 random numbers
func GenerateWinningNumbers() [5]int {
	// For random numbers at all execution
	rand.Seed(time.Now().UnixNano())
	var numbers [5]int

	for i := 0; i < len(numbers); i++ {
		numbers[i] = rand.Intn(16)
	}

	return numbers
}
