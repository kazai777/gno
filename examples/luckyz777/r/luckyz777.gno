package luckyz

import (
	"std"

	"gno.land/p/demo/grc/grc20"
	"gno.land/p/demo/ufmt"
)

var (
	luckyz *grc20.AdminToken
	admin  std.Address = "g14950fuewvuuup3j5z9jchy78xe5xzfhhcwl07f"
)

func init() {
	luckyz = grc20.NewAdminToken("Luckyz", "LUCKY", 6)
	luckyz.Mint(admin, 100000000)
}

func TotalSupply() uint64 {
	return luckyz.TotalSupply()
}

func Render(path string) string {
	return ufmt.Sprintf("Total Supply: %d\n", luckyz.TotalSupply())
}
