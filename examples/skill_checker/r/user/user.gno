package user

import (
	"bytes"
	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/seqid"
	"gno.land/p/demo/ufmt"
	puser "gno.land/p/kazai/user"
)

var userTree *avl.Tree
var usersID seqid.ID

func init() {
	userTree = avl.NewTree()
}

func NewUser(pseudo string) (string, string) {
	txSender := std.GetOrigCaller()
	id := usersID.Next()

	if pseudo == "" {
		panic("Pseudo is empty")
	}

	// check if pseudo already exists
	userTree.Iterate("", "", func(key string, value interface{}) bool {
		u := value.(*puser.User)
		if u.Pseudo == pseudo {
			panic("Pseudo already exists")
		}
		return false
	})

	u := puser.NewUser(txSender, pseudo)

	userTree.Set(id.Binary(), u)

	return id.String(), "New user ok"
}

func AddSkill(userID string, skillName string) (string, int) {
	txSender := std.GetOrigCaller()
	id, err := seqid.FromString(userID)
	if err != nil {
		panic("Invalid user ID")
	}

	u, ok := userTree.Get(id.Binary())
	if !ok {
		panic("User not found")
	}

	// check if user is the sender
	if u.(*puser.User).Address != txSender {
		panic("User not allowed to add skill")
	}

	// check if skill already exists
	for _, skill := range u.(*puser.User).Skills {
		if skill.Name == skillName {
			panic("Skill already exists")
		}
	}

	user := u.(*puser.User)

	newSkillID := len(user.Skills) + 1

	newSkill := puser.Skill{
		ID:     newSkillID,
		Name:   skillName,
		Proofs: make([]puser.Proof, 0),
	}

	user.AddSkill(newSkill)

	return "Skill added", newSkillID
}

func AddProof(userID string, skillID int, url string, comment string) string {
	txSender := std.GetOrigCaller()

	id, err := seqid.FromString(userID)
	if err != nil {
		panic("Invalid user ID")
	}

	u, ok := userTree.Get(id.Binary())
	if !ok {
		panic("User not found")
	}

	user := u.(*puser.User)

	// check if user is the sender
	if user.Address != txSender {
		panic("User not allowed to add proof")
	}

	found := false
	for i, skill := range user.Skills {
		if skill.ID == skillID {
			newLink := puser.Link{
				URL:     url,
				Comment: comment,
			}

			newProof := puser.Proof{
				Links: []puser.Link{newLink},
			}

			user.Skills[i].Proofs = append(user.Skills[i].Proofs, newProof)
			found = true
			break
		}
	}

	if !found {
		panic("Skill not found")
	}

	return "Proof added"
}

func Render(path string) string {
	if path == "" {
		return renderHomepage()
	}

	return "unknown page"
}

func renderHomepage() string {
	var b bytes.Buffer

	b.WriteString("# All Users\n\n")

	if userTree.Size() == 0 {
		b.WriteString("### No users currently!\n")
	} else {
		b.WriteString("### Users\n")
		userTree.Iterate("", "", func(key string, value interface{}) bool {
			u := value.(*puser.User)

			userID, _ := seqid.FromBinary(key)
			readableID := userID.String()

			b.WriteString(ufmt.Sprintf("- **Pseudo**: %s | **Address**: %s | ID : %s\n", u.Pseudo, u.Address, readableID))
			b.WriteString("  - **Skills**:\n")
			if len(u.Skills) == 0 {
				b.WriteString("    - No skills listed.\n")
			} else {
				for _, skill := range u.Skills {
					b.WriteString(ufmt.Sprintf("    - %s \n ", skill.Name))
					if len(skill.Proofs) > 0 {
						b.WriteString("      - **Proofs**:\n")
						for _, proof := range skill.Proofs {
							for _, link := range proof.Links {
								b.WriteString(ufmt.Sprintf("        - [%s](%s) - %s\n", link.URL, link.URL, link.Comment))
							}
						}
					}
				}
			}
			b.WriteString("  - **Notes**:\n")
			if len(u.Notes) == 0 {
				b.WriteString("    - No notes available.\n")
			} else {
				for _, note := range u.Notes {
					b.WriteString(ufmt.Sprintf("    - **From**: %s | **Date**: %s\n", note.Author, note.Date.Format("2006-01-02")))
					b.WriteString(ufmt.Sprintf("      - \"%s\"\n", note.Content))
				}
			}
			b.WriteString(ufmt.Sprintf("  - **Score**: %d | **Level**: %s\n\n", u.Score, u.Level))
			b.WriteString("\n")

			return false
		})
	}
	return b.String()
}
