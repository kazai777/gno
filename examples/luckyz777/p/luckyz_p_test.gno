package luckyz_p

import (
	"testing"
)

func TestGenerateRandomNumbers(t *testing.T) {
	numbers := GenerateWinningNumbers()

	// Check if the array contains 5 numbers
	if len(numbers) != 5 {
		t.Errorf("Expected 5 numbers, got %d", len(numbers))
	}

	// Check if each numbers is in the range 0 to 15
	for _, num := range numbers {
		if num < 0 || num > 15 {
			t.Errorf("Number out of expected range (0-15): %d", num)
		}
	}
}
