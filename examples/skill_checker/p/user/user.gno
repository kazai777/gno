package user

import (
	"std"
	"time"
)

type User struct {
	Address    std.Address
	Pseudo     string
	Skills     []Skill
	Score      int
	Evaluators bool
	Notes      []Note
	Level      string
}

type Skill struct {
	ID     int
	Name   string
	Proofs []Proof
}

type Proof struct {
	Links []Link
}

type Link struct {
	URL     string
	Comment string
}

type Note struct {
	Author  std.Address
	Content string
	Date    time.Time
}

func NewUser(address std.Address, pseudo string) *User {
	return &User{
		Address: address,
		Pseudo:  pseudo,
		Skills:  make([]Skill, 0),
		Score:   0,
		Notes:   make([]Note, 0),
		Level:   "beginner",
	}
}

func (u *User) AddSkill(skill Skill) {
	u.Skills = append(u.Skills, skill)
}

func (u *User) AddNote(note Note) {
	u.Notes = append(u.Notes, note)
}

func (u *User) AddProof(skillID int, newProof Proof) {
	for i, skill := range u.Skills {
		if skill.ID == skillID {
			u.Skills[i].Proofs = append(u.Skills[i].Proofs, newProof)
			break
		}
	}
}

func (u *User) UpdateScore(newScore int) {
	u.Score = newScore
}

func (u *User) UpdateLevel(newLevel string) {
	u.Level = newLevel
}
