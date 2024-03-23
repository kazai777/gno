package gnolotto

import (
	"std"
	"time"
)

type Ticket struct {
	Numbers [5]int
	Owner	std.Address
}

type Lottery struct {
	Tickets	[]Ticket
	WinningNumbers 	[5]int
	DrawTime	time.Time
	PrizePool	int64
}

// Intializes a new lottery instance with a specified draw time and prize pool
func NewLottery(drawTime time.Time, prizePool int64) *Lottery {
	return &Lottery{
		DrawTime: drawTime,
		PrizePool: prizePool,
		Tickets: make([]Ticket, 0),
	}
}

// Adds a new ticket to the lottery
func (l *Lottery) AddTicket(numbers [5]int, owner std.Address) {
    l.Tickets = append(l.Tickets, Ticket{Numbers: numbers, Owner: owner})
}

// Selects the winning numbers for the lottery. This function should only be called after the draw time has passed
func (l *Lottery) Draw(winningNumbers [5]int) {
	l.WinningNumbers = winningNumbers
}

// Iterates through the tickets to find winners and calculate rewards
func (l *Lottery) CheckWinners() (winners []std.Address, prizePerWinner int64) {
	prizePerWinner = l.PrizePool / int64(len(l.Tickets))
	for _, ticket := range l.Tickets {
		if ticket.Numbers == l.WinningNumbers {
			winners = append(winners, ticket.Owner)
		}
	}
	return winners, prizePerWinner
}