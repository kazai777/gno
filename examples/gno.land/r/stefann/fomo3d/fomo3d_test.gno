package fomo3d

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/grc/grc721"
	"gno.land/p/demo/ownable"
	"gno.land/p/demo/testutils"
	"gno.land/p/demo/urequire"
)

// Reset game state
func setupTestGame(t *testing.T) {
	gameState = GameState{
		StartBlock:   0,
		EndBlock:     0,
		LastKeyBlock: 0,
		LastBuyer:    "",
		Jackpot:      0,
		KeyPrice:     MIN_KEY_PRICE,
		TotalKeys:    0,
		Ended:        true,
		CurrentRound: 0,
		NextPot:      0,
		OwnerFee:     0,
	}
	players = avl.NewTree()
	Ownable = ownable.New()
}

// Test ownership functionality
func TestOwnership(t *testing.T) {
	owner := testutils.TestAddress("owner")
	nonOwner := testutils.TestAddress("nonOwner")

	// Set up initial owner
	std.TestSetOrigCaller(owner)
	std.TestSetOrigPkgAddr(owner)
	setupTestGame(t)

	// Transfer ownership to nonOwner first to test ownership functions
	std.TestSetOrigCaller(owner)
	urequire.NotPanics(t, func() {
		Ownable.TransferOwnership(nonOwner)
	})

	// Test fee accumulation
	StartGame()
	payment := MIN_KEY_PRICE * 10
	std.TestSetOrigCaller(owner)
	std.TestSetOrigSend(std.Coins{{"ugnot", payment}}, nil)
	std.TestIssueCoins(owner, std.Coins{{"ugnot", payment}})
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", payment}})
	BuyKeys()

	// Verify fee accumulation
	_, fees := GetOwnerInfo()
	expectedFees := payment * OWNER_FEE_PERCENT / 100
	urequire.Equal(t, expectedFees, fees)

	// Test unauthorized fee claim (using old owner)
	std.TestSetOrigCaller(owner)
	urequire.PanicsWithMessage(t, "ownable: caller is not owner", ClaimOwnerFee)

	// Test authorized fee claim (using new owner)
	std.TestSetOrigCaller(nonOwner)
	initialBalance := std.GetBanker(std.BankerTypeRealmSend).GetCoins(nonOwner)
	std.TestIssueCoins(std.CurrentRealm().Addr(), std.Coins{{"ugnot", expectedFees}})
	urequire.NotPanics(t, ClaimOwnerFee)

	// Verify fees were claimed
	_, feesAfter := GetOwnerInfo()
	urequire.Equal(t, int64(0), feesAfter)

	finalBalance := std.GetBanker(std.BankerTypeRealmSend).GetCoins(nonOwner)
	urequire.Equal(t, initialBalance.AmountOf("ugnot")+expectedFees, finalBalance.AmountOf("ugnot"))
}

// Test full game flow
func TestFullGameFlow(t *testing.T) {
	setupTestGame(t)

	player1 := testutils.TestAddress("player1")
	player2 := testutils.TestAddress("player2")
	player3 := testutils.TestAddress("player3")

	// Test initial state
	urequire.Equal(t, int64(0), gameState.CurrentRound)
	urequire.Equal(t, MIN_KEY_PRICE, gameState.KeyPrice)
	urequire.Equal(t, true, gameState.Ended)

	// Start game
	urequire.NotPanics(t, StartGame)
	urequire.Equal(t, false, gameState.Ended)
	urequire.Equal(t, std.GetHeight(), gameState.StartBlock)
	urequire.Equal(t, int64(1), gameState.CurrentRound)

	t.Run("buying keys", func(t *testing.T) {
		// Test insufficient payment
		std.TestSetOrigCaller(player1)
		std.TestIssueCoins(player1, std.Coins{{"ugnot", MIN_KEY_PRICE - 1}})
		std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE - 1}}, nil)
		std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE - 1}})
		urequire.PanicsWithMessage(t, ErrInsufficientPayment.Error(), BuyKeys)

		// Test successful key purchase
		payment := MIN_KEY_PRICE * 3
		std.TestSetOrigSend(std.Coins{{"ugnot", payment}}, nil)
		std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", payment}})

		currentBlock := std.GetHeight()
		urequire.NotPanics(t, BuyKeys)

		// Verify time extension
		_, endBlock, _, _, _, _, _, _, _, _ := GetGameState()
		urequire.Equal(t, currentBlock+TIME_EXTENSION, endBlock)

		// Verify player state
		keys, dividends := GetPlayerInfo(player1.String())

		urequire.Equal(t, int64(3), keys)
		urequire.Equal(t, int64(0), dividends)
		urequire.Equal(t, player1, gameState.LastBuyer)

		// Verify game state
		_, endBlock, _, buyer, pot, price, keys, isEnded, nextPot, round := GetGameState()
		urequire.Equal(t, player1, buyer)
		urequire.Equal(t, int64(3), keys)
		urequire.Equal(t, false, isEnded)

		urequire.Equal(t, payment*JACKPOT_PERCENT/100, pot)

		// Verify owner fee
		_, ownerFees := GetOwnerInfo()
		urequire.Equal(t, payment*OWNER_FEE_PERCENT/100, ownerFees)
	})

	t.Run("dividend distribution and claiming", func(t *testing.T) {
		// Player 2 buys keys
		std.TestSetOrigCaller(player2)
		payment := gameState.KeyPrice * 2 // Buy 2 keys using current keyPrice
		std.TestSetOrigSend(std.Coins{{"ugnot", payment}}, nil)
		std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", payment}})
		urequire.NotPanics(t, BuyKeys)

		// Check player1 received dividends
		keys1, dividends1 := GetPlayerInfo(player1.String())

		urequire.Equal(t, int64(3), keys1)
		expectedDividends := payment * DIVIDENDS_PERCENT / 100 * 3 / gameState.TotalKeys
		urequire.Equal(t, expectedDividends, dividends1)

		// Test claiming dividends
		{
			// Player1 claims dividends
			std.TestSetOrigCaller(player1)
			initialBalance := std.GetBanker(std.BankerTypeRealmSend).GetCoins(player1)
			urequire.NotPanics(t, ClaimDividends)

			// Verify dividends were claimed
			_, dividendsAfter := GetPlayerInfo(player1.String())
			urequire.Equal(t, int64(0), dividendsAfter)

			lastBuyerBalance := std.GetBanker(std.BankerTypeRealmSend).GetCoins(player1)
			urequire.Equal(t, initialBalance.AmountOf("ugnot")+expectedDividends, lastBuyerBalance.AmountOf("ugnot"))
		}
	})

	t.Run("game ending", func(t *testing.T) {
		// Try ending too early
		urequire.PanicsWithMessage(t, ErrGameNotInProgress.Error(), EndGame)

		// Skip to end of current time window
		currentEndBlock := gameState.EndBlock
		std.TestSkipHeights(currentEndBlock - std.GetHeight() + 1)

		// End game successfully
		urequire.NotPanics(t, EndGame)
		urequire.Equal(t, true, gameState.Ended)
		urequire.Equal(t, int64(1), gameState.CurrentRound)

		// Verify winner received jackpot
		lastBuyerBalance := std.GetBanker(std.BankerTypeRealmSend).GetCoins(gameState.LastBuyer)
		urequire.Equal(t, gameState.Jackpot, lastBuyerBalance.AmountOf("ugnot"))

		// Verify NFT was minted to winner
		balance, err := BalanceOf(gameState.LastBuyer)
		urequire.NoError(t, err)
		urequire.Equal(t, uint64(1), balance)

		// Check NFT metadata
		tokenID := grc721.TokenID("1")
		metadata, err := TokenMetadata(tokenID)

		urequire.NoError(t, err)
		urequire.Equal(t, "Fomo3D Winner - Round #1", metadata.Name)
	})

	// Test new round
	t.Run("new round", func(t *testing.T) {
		// Calculate expected next pot from previous round
		payment1 := MIN_KEY_PRICE * 3
		// After buying 3 keys, price increased by 3% (1% per key)
		secondKeyPrice := MIN_KEY_PRICE + (MIN_KEY_PRICE * 3 / 100)
		payment2 := secondKeyPrice * 2
		expectedNextPot := (payment1 * NEXT_ROUND_POT / 100) + (payment2 * NEXT_ROUND_POT / 100)

		// Start new round
		urequire.NotPanics(t, StartGame)
		urequire.Equal(t, false, gameState.Ended)
		urequire.Equal(t, int64(2), gameState.CurrentRound)

		start, end, last, buyer, pot, price, keys, isEnded, nextPot, round := GetGameState()
		urequire.Equal(t, int64(2), round)
		urequire.Equal(t, expectedNextPot, pot)
		urequire.Equal(t, int64(0), nextPot)
	})
}

// Test individual components
func TestStartGame(t *testing.T) {
	setupTestGame(t)

	// Test starting first game
	urequire.NotPanics(t, StartGame)
	urequire.Equal(t, false, gameState.Ended)
	urequire.Equal(t, std.GetHeight(), gameState.StartBlock)

	// Test cannot start while game in progress
	urequire.PanicsWithMessage(t, ErrGameInProgress.Error(), StartGame)
}

func TestBuyKeys(t *testing.T) {
	setupTestGame(t)
	StartGame()

	player := testutils.TestAddress("player")
	std.TestSetOrigCaller(player)

	// Test invalid coin denomination
	std.TestIssueCoins(player, std.Coins{{"invalid", MIN_KEY_PRICE}})
	std.TestSetOrigSend(std.Coins{{"invalid", MIN_KEY_PRICE}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"invalid", MIN_KEY_PRICE}})
	urequire.PanicsWithMessage(t, ErrInvalidPayment.Error(), BuyKeys)

	// Test multiple coin types
	std.TestIssueCoins(player, std.Coins{{"ugnot", MIN_KEY_PRICE}, {"other", 100}})
	std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE}, {"other", 100}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE}, {"other", 100}})
	urequire.PanicsWithMessage(t, ErrInvalidPayment.Error(), BuyKeys)

	// Test insufficient payment
	std.TestIssueCoins(player, std.Coins{{"ugnot", MIN_KEY_PRICE - 1}})
	std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE - 1}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE - 1}})
	urequire.PanicsWithMessage(t, ErrInsufficientPayment.Error(), BuyKeys)

	// Test successful purchase
	std.TestIssueCoins(player, std.Coins{{"ugnot", MIN_KEY_PRICE * 2}})
	std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE * 2}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE * 2}})
	urequire.NotPanics(t, BuyKeys)
}

func TestClaimDividends(t *testing.T) {
	setupTestGame(t)
	StartGame()

	player := testutils.TestAddress("player")
	std.TestSetOrigCaller(player)

	// Test claiming with no dividends
	urequire.PanicsWithMessage(t, ErrNoDividendsToClaim.Error(), ClaimDividends)

	// Setup player with dividends
	std.TestIssueCoins(player, std.Coins{{"ugnot", MIN_KEY_PRICE}})
	std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE}})
	BuyKeys()

	// Have another player buy to generate dividends
	player2 := testutils.TestAddress("player2")
	std.TestSetOrigCaller(player2)
	std.TestIssueCoins(player2, std.Coins{{"ugnot", MIN_KEY_PRICE * 2}})
	std.TestSetOrigSend(std.Coins{{"ugnot", MIN_KEY_PRICE * 2}}, nil)
	std.TestIssueCoins(std.GetOrigPkgAddr(), std.Coins{{"ugnot", MIN_KEY_PRICE * 2}})
	BuyKeys()

	// Test successful claim
	std.TestSetOrigCaller(player)
	urequire.NotPanics(t, ClaimDividends)
}
