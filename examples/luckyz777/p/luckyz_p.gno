package luckyz_p

import (
	"std"
	"time"
)

type Lotery struct {
	name          string      // Name of lotery
	owner         std.Address // Owner of lotery (admin)
	deadline      time.Time   // Lotery deadline (every friday at 9:00pm)
	newLotery     time.Time   // New lotery (every friday at 11:pm)
	maxUsers      int64       // Max number of users (1.000.000 max)
	userList      *avl.Tree   // Signed-up users address -> numbers choosing
	loteryNumbers []int       // Randomly generated numbers by realm
}
