package profile

import (
    "bytes"
    "gno.land/p/demo/avl"
    "gno.land/p/demo/ufmt"
    "std"
	"time"
)

type UserProfile struct {
    Username string
    Address  std.Address
    Picture  string
    Age      string
    Gender   string
    Website  string
    Country  string
    City     string
	ModificationHistory map[string][]string
}

var profiles *avl.Tree
var usernameIndex *avl.Tree // Index to quickly find a profile by username

func init() {
    profiles = avl.NewTree()
    usernameIndex = avl.NewTree()
}

func CreateProfile(username, picture, age, gender, website, country, city string) {
    caller := std.GetOrigCaller()

    // Check if a profile already exists for this address
    if _, exists := profiles.Get(caller.String()); exists {
        panic("A profile already exists for this address")
    }

     // Check if the username is already taken
	if username != "" {
        _, exists := usernameIndex.Get(username)
        if exists {
            panic("Username is already taken")
        }
    }


    profile := UserProfile{
        Username: username,
        Address:  caller,
        Picture:  picture,
        Age: age,
        Gender: gender,
        Website:  website,
        Country:  country,
        City: city,
    }

    // Save the profile
    profiles.Set(caller.String(), profile)

    // Update the username index if the username is provided
    if username != "" {
        usernameIndex.Set(username, caller.String())
    }
}

func UpdateProfile(username, picture, age, gender, website, country, city string) {
    caller := std.GetOrigCaller()
    value, exists := profiles.Get(caller.String())
    if !exists {
        panic("Profile not found")
    }

    // Retrieve the existing profile
    existingProfile := value.(UserProfile)

    // Initialize the ModificationHistory map if it's nil
    if existingProfile.ModificationHistory == nil {
        existingProfile.ModificationHistory = make(map[string][]string)
    }

    // Function to update the profile field if changed
    updateField := func(field *string, newValue, fieldName string, profile *UserProfile) {
        if newValue != "" && *field != newValue {
			changeDescription := time.Now().Format(time.RFC3339) + ": Changed from " + *field + " to " + newValue
			if profile.ModificationHistory == nil {
				profile.ModificationHistory = make(map[string][]string)
			}
			profile.ModificationHistory[fieldName] = append(profile.ModificationHistory[fieldName], changeDescription)
			*field = newValue
		}
    }

    // Update fields and log changes
    updateField(&existingProfile.Username, username, "Username", &existingProfile)
    updateField(&existingProfile.Picture, picture, "Picture", &existingProfile)
    updateField(&existingProfile.Age, age, "Age", &existingProfile)
    updateField(&existingProfile.Gender, gender, "Gender", &existingProfile)
    updateField(&existingProfile.Website, website, "Website", &existingProfile)
    updateField(&existingProfile.Country, country, "Country", &existingProfile)
    updateField(&existingProfile.City, city, "City", &existingProfile)

    // Update the profile in the tree
    profiles.Set(caller.String(), existingProfile)

    // Update the username index if the username is changed
    if username != ""  {
        usernameIndex.Set(username, caller.String())
    }
}

func GetProfileByAddress(address std.Address) (UserProfile, bool) {
    if value, exists := profiles.Get(address.String()); exists {
        return value.(UserProfile), true
    }
    return UserProfile{}, false
}

func GetProfileByUsername(username string) (UserProfile, bool) {
    if addr, exists := usernameIndex.Get(username); exists {
        return GetProfileByAddress(std.Address(addr.(string)))
    }
    return UserProfile{}, false
}

func Render(path string) string {
    if path == "" {
		return renderHome()
	}

    return "unknown path"
}

func renderHome() string {
	var b bytes.Buffer

	profiles.Iterate("", "", func(key string, value interface{}) bool {
		profile := value.(UserProfile)
		b.WriteString(ufmt.Sprintf("Username: %s\n\n", profile.Username))
		b.WriteString(ufmt.Sprintf("Address: %s\n\n", profile.Address))
		b.WriteString(ufmt.Sprintf("Picture: %s\n\n", profile.Picture))
		b.WriteString(ufmt.Sprintf("Age: %s\n\n", profile.Age))
		b.WriteString(ufmt.Sprintf("Gender: %s\n\n", profile.Gender))
		b.WriteString(ufmt.Sprintf("Website: %s\n\n", profile.Website))
		b.WriteString(ufmt.Sprintf("Country: %s\n\n", profile.Country))
		b.WriteString(ufmt.Sprintf("City: %s\n\n", profile.City))
		
		// Properly iterate over the modification history map
        if profile.ModificationHistory != nil {
			b.WriteString("ModificationHistory:\n\n")
			for key, changes := range profile.ModificationHistory {
				b.WriteString(ufmt.Sprintf("%s:\n", key))
				for _, change := range changes {
					b.WriteString(ufmt.Sprintf("  %s | \n", change))
				}
			}
		} else {
			b.WriteString("No modifications recorded.\n")
		}

		b.WriteString("\n")

		return false
	})

	return b.String()
}
