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

// Déclaration d'un arbre AVL pour stocker des instances de loteries.
var lotteries *avl.Tree

// L'adresse de l'administrateur autorisé à effectuer des tirages et à distribuer des récompenses.
var admin std.Address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"

func init() {
	lotteries = avl.NewTree()
}

// Crée une nouvelle loterie et l'ajoute à l'arbre AVL.
func CreateLottery(drawTime int64, prizePool int64) (int, string) {
	// Générer un identifiant unique pour la loterie.
	lotteryID := lotteries.Size()
	lottery := gnolotto.NewLottery(time.Unix(drawTime, 0), prizePool)
	lotteries.Set(ufmt.Sprintf("%d", lotteryID), lottery)
	return lotteryID, "Lottery created successfully"
}

// Buy ticket for a specific lottery.
func BuyTicket(lotteryID int, numbers [5]int) {
	id := ufmt.Sprintf("%d", lotteryID)
	lotteryRaw, exists := lotteries.Get(id)
	if !exists {
		panic("Lottery not found")
	}

	l, ok := lotteryRaw.(*gnolotto.Lottery)
	if !ok {
		panic("Failed to cast lottery to *Lottery")
	}

	caller := std.GetOrigCaller()
	l.AddTicket(numbers, caller)
}

// Effectue le tirage des numéros gagnants pour une loterie spécifique.
func Draw(lotteryID int, winningNumbers [5]int) {
	id := ufmt.Sprintf("%d", lotteryID)
	if std.GetOrigCaller() != admin {
		panic("Only the admin can draw the winning numbers")
	}
	lotteryRaw, exists := lotteries.Get(id)
	if !exists {
		panic("Lottery not found")
	}
	l, ok := lotteryRaw.(*gnolotto.Lottery)
	if !ok {
		panic("Failed to cast lottery to *Lottery")
	}
	l.Draw(winningNumbers)
}

// Distribue les récompenses pour une loterie spécifique.
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

    b.WriteString("# Welcome to GnoLotto Lottery Overview\n\n")

    if lotteries.Size() == 0 {
        b.WriteString("### No lotteries available currently!\n")
        return b.String()
    }

    lotteries.Iterate("", "", func(key string, value interface{}) bool {
        l := value.(*gnolotto.Lottery)

        b.WriteString(
            ufmt.Sprintf(
                "## Lottery ID: %s\n",
                key,
            ),
        )

        b.WriteString(
            ufmt.Sprintf(
                "Draw Time: %s\n",
                l.DrawTime.Format("Mon Jan _2 15:04:05 2006"),
            ),
        )

        b.WriteString(
            ufmt.Sprintf(
                "Prize Pool: %d\n\n",
                l.PrizePool,
            ),
        )

        return false // Continuer l'itération sur tous les éléments
    })

    return b.String()
}