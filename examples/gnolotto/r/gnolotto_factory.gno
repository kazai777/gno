package gnolotto_factory

import (
	"bytes"
	"time"
	"strconv"
	"strings"
	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
	"gno.land/p/demo/gnolotto"
)

var lotteries *avl.Tree

var admin std.Address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"

func init() {
	lotteries = avl.NewTree()
}

func CreateLottery(drawTime int64, prizePool int64) (int, string) {
	if drawTime < time.Now().Unix() {
		return -1, "Invalid draw time"
	}
	
	if std.GetOrigCaller() != admin {
		return -1, "Only the admin can create a lottery"
	}

	// Get the amount of GNOT sent in the transaction.
	sentCoins := std.GetOrigSend()
	amount := sentCoins.AmountOf("ugnot")

	if prizePool != amount {
		// If amount sent is not equal to the prize pool, refund the sender.
		banker := std.GetBanker(std.BankerTypeRealmSend)
		send := std.Coins{{"ugnot", int64(amount)}}
		banker.SendCoins(std.GetOrigPkgAddr(), std.GetOrigCaller(), send)
		return -1, "Prize pool must match the transaction value"
	}

	lotteryID := lotteries.Size()
	lottery := gnolotto.NewLottery(time.Unix(drawTime, 0), prizePool)

	lotteries.Set(ufmt.Sprintf("%d", lotteryID), lottery)
	return lotteryID, "Lottery created successfully"
}

// Buy ticket for a specific lottery.
func BuyTicket(lotteryID int, numbersStr string) (int, string) {
    id := ufmt.Sprintf("%d", lotteryID)
    lotteryRaw, exists := lotteries.Get(id)
    if !exists {
        panic("Lottery not found")
    }

    // Convert string to slice of integers.
    numbersSlice := strings.Split(numbersStr, ",")
    numbers := make([]int, len(numbersSlice))
    for i, numStr := range numbersSlice {
        num, err := strconv.Atoi(numStr)
        if err != nil {
            panic("Invalid number: " + err.Error())
        }
        numbers[i] = num
    }

	// Verify if the numbers are unique.
    uniqueNumbers := make(map[int]bool)
    for _, num := range numbers {
        if uniqueNumbers[num] {
            return -1, "Numbers must be unique"
        }
        uniqueNumbers[num] = true
    }

	l, _ := lotteryRaw.(*gnolotto.Lottery)

	if time.Now().Unix() > l.DrawTime.Unix() {
		return -1, "This lottery has already ended"
	}

	if len(numbers) > 5 || len(numbers) < 5 {
		return -1, "You must select exactly 5 numbers"
	}

	for _, num := range numbers {
		if num > 15 || num < 1 {
			return -1, "Invalid number, select number range from 1 to 15"
		}
	}

    caller := std.GetOrigCaller()
    l.AddTicket(numbersStr, caller)

    return 1, "Ticket purchased successfully"
}

// Draw the winning numbers for a specific lottery.
func Draw(lotteryID int, winningNumbersStr string) {
	id := ufmt.Sprintf("%d", lotteryID)
	if std.GetOrigCaller() != admin {
		panic("Only the admin can draw the winning numbers")
	}
	lotteryRaw, exists := lotteries.Get(id)
	if !exists {
		panic("Lottery not found")
	}

	winningNumbersSlice := strings.Split(winningNumbersStr, ",")
	winningNumbers := make([]int, len(winningNumbersSlice))
	for i, numStr := range winningNumbersSlice {
		num, err := strconv.Atoi(numStr)
		if err != nil {
			panic("Invalid number: " + err.Error())
		}
		winningNumbers[i] = num
	}

	l, ok := lotteryRaw.(*gnolotto.Lottery)
	if !ok {
		panic("Failed to cast lottery to *Lottery")
	}
	l.Draw(winningNumbersStr)
}

// Distribute the prizes for a specific lottery.
func DistributePrizes(lotteryID int) {
	id := ufmt.Sprintf("%d", lotteryID)
	if std.GetOrigCaller() != admin {
		panic("Only the admin can distribute the prizes")
	}
	lotteryRaw, exists := lotteries.Get(id)
	if !exists {
		panic("Lottery not found")
	}
	l, ok := lotteryRaw.(*gnolotto.Lottery)
	if !ok {
		panic("Failed to cast lottery to *Lottery")
	}
	winners, prizePerWinner := l.CheckWinners()
	/*for _, winner := range winners {
		std.Transfer(winner, prizePerWinner)
	}*/
}

func Render(path string) string {
	if path == "" {
		return renderHomepage()
	}

	return "unknown page"
}

func renderHomepage() string {
    var b bytes.Buffer

    b.WriteString("# Welcome to GnoLotto\n\n")

    if lotteries.Size() == 0 {
        b.WriteString("### *No lotteries available currently!*\n")
        return b.String()
    }

    lotteries.Iterate("", "", func(key string, value interface{}) bool {
        l := value.(*gnolotto.Lottery)

        b.WriteString(
            ufmt.Sprintf(
                "## Lottery ID: *%s*\n",
                key,
            ),
        )

        b.WriteString(
            ufmt.Sprintf(
                "Draw Time: *%s*\n",
                l.DrawTime.Format("Mon Jan _2 15:04:05 2006"),
            ),
        )

        b.WriteString(
            ufmt.Sprintf(
                "Prize Pool: *%d* GNOT\n\n",
                l.PrizePool,
            ),
        )

        if time.Now().Unix() > l.DrawTime.Unix() {
            // If the lottery has ended, display the winners.
            winners, _ := l.CheckWinners()
            if len(winners) > 0 {
                b.WriteString("Winners:\n")
                for _, winner := range winners {
                    b.WriteString(ufmt.Sprintf("- *%s*\n", winner.String()))
                }
            } else {
                b.WriteString("*No winners for this lottery.*\n")
            }
        } else {
            // If the lottery is still ongoing, display the participants.
            if len(l.Tickets) > 0 {
                b.WriteString("Participants:\n")
                for _, ticket := range l.Tickets {
                    b.WriteString(ufmt.Sprintf("- *%s*\n", ticket.Owner.String()))
                }
            } else {
                b.WriteString("*No participants yet.*\n")
            }
        }

        b.WriteString("\n")
        return false
    })

	// Récupère la balance du contrat
	banker := std.GetBanker(std.BankerTypeReadonly)
	contractAddress := std.GetOrigPkgAddr()
	coins := banker.GetCoins(contractAddress)
		
	// Ajoute la balance du contrat à l'affichage
	b.WriteString("## Contract Balance:\n")
	b.WriteString(coins.String() + "\n\n")
	

    return b.String()
}
