package main

import (
	govdao "gno.land/r/gov/dao"
	_ "gno.land/r/gov/proposals/prop1"
)

func main() {
	println("--")
	println(govdao.Render(""))
	println("--")
	println(govdao.Render("1"))
	println("--")
	govdao.VoteOnProposal(1, "YES")
	println("--")
	println(govdao.Render("1"))
	println("--")
	govdao.ExecuteProposal(1)
	println("--")
	println(govdao.Render("1"))
}

// Output:
// --
// - [/r/gov/dao:0](0) - manual valset changes proposal example (by g1tk0fscr3p5g8hnhxq6v93jxcpm5g3cstlxfxa3)
// --
// # Prop#0
//
// manual valset changes proposal example
// Status: active
// Author: g1tk0fscr3p5g8hnhxq6v93jxcpm5g3cstlxfxa3
// --
// --
// # Prop#0
//
// manual valset changes proposal example
// Status: accepted
// Author: g1tk0fscr3p5g8hnhxq6v93jxcpm5g3cstlxfxa3
// --
// --
// # Prop#0
//
// manual valset changes proposal example
// Status: success
// Author: g1tk0fscr3p5g8hnhxq6v93jxcpm5g3cstlxfxa3
