package gnolotto

import (
	"std"
	"time"
	"strings"
	"strconv"
)

type Ticket struct {
	Numbers []int
	Owner	std.Address
}

type Lottery struct {
	Tickets	[]Ticket
	WinningNumbers 	[]int
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
func (l *Lottery) AddTicket(numbersStr string, owner std.Address) {
	numbersSlice := strings.Split(numbersStr, ",")
	numbers := make([]int, len(numbersSlice))

	for i, numStr := range numbersSlice {
		num, err := strconv.Atoi(numStr)
		if err != nil {
			panic("Invalid number")
		}
		numbers[i] = num
	}
    l.Tickets = append(l.Tickets, Ticket{Numbers: numbers, Owner: owner})
}

func (l *Lottery) Draw() {
    var timestamp int64 = time.Now().UnixNano()
    if timestamp < 0 {
        timestamp = -timestamp
    }

    l.WinningNumbers = nil

    numbersMap := make(map[int]bool)

    for len(l.WinningNumbers) < 5 {
        var simpleSeed int64 = timestamp % 10000
        
        number := int(simpleSeed % 15) + 1

        if !numbersMap[number] {
            l.WinningNumbers = append(l.WinningNumbers, number)
            numbersMap[number] = true
        }

        timestamp += 1
    }
}

// Itterate over all tickets and check if they are winners
func(l *Lottery) CheckWinners() []std.Address {
	var winningOwners []std.Address

	for _, ticket := range l.Tickets {
		matchCount := 0

		for _, tNum := range ticket.Numbers {
			for _, wNum := range l.WinningNumbers {
				if tNum == wNum {
					matchCount++
					break
				}
			}
		}

		if matchCount == len(l.WinningNumbers) {
			winningOwners = append(winningOwners, ticket.Owner)
		}
	}

	return winningOwners
}

func (l *Lottery) PayWinners(winningOwners []std.Address) {
    if len(winningOwners) == 0 {
        return
    }

    // Calcul amount for each winner
    var reward int64 = l.PrizePool / int64(len(winningOwners))

    banker := std.GetBanker(std.BankerTypeRealmSend)

    for _, owner := range winningOwners {
        send := std.Coins{{"ugnot", reward}}
        banker.SendCoins(std.GetOrigPkgAddr(), owner, send)
    }

    l.PrizePool = 0
}
