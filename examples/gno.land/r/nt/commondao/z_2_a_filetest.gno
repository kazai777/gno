package main

import (
	"std"
	"testing"

	"gno.land/r/nt/commondao"
)

const (
	owner = std.Address("g16jpf0puufcpcjkph5nxueec8etpcldz7zwgydq") // @devx
	user  = std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5") // @test1
	name  = "Foo"
)

var realmAddr = std.DerivePkgAddr("gno.land/r/test")

func init() {
	// Invite a user to be able to start creating DAOs
	testing.SetRealm(std.NewUserRealm(owner))
	commondao.Invite(cross, user)
}

func main() {
	// The origin must be the invited user where invitation
	// is removed after the first user call to create a DAO
	testing.SetRealm(std.NewUserRealm(user))
	testing.SetRealm(std.NewCodeRealm("gno.land/r/test"))

	dao := commondao.New(name)
	if dao == nil {
		panic("expected DAO to be created")
	}

	println(dao.Name() == name)
	println(commondao.IsOwner(realmAddr, dao.ID()))
	println(commondao.IsInvited(user))
	println(commondao.GetOptions(dao.ID()) != nil)
}

// Output:
// true
// true
// false
// true
