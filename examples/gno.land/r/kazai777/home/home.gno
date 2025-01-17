package home

import (
	"std"
	"time"

	"gno.land/p/demo/subscription"
	"gno.land/p/demo/subscription/lifetime"
	"gno.land/p/demo/subscription/recurring"
	"gno.land/p/demo/ufmt"
	"gno.land/p/moul/md"
	"gno.land/p/moul/txlink"
)

var newsletterVisble bool

var (
	avatar = "https://ibb.co/CsN73Qn"
	githubLink = "https://github.com/kazai777"
	aboutMe = "Hi im kazai777 🔮"
)

var (
	subMonthly subscription.Subscription
	subLifetime subscription.Subscription
)

func init() {
	sm := recurring.NewRecurringSubscription(30*24*time.Hour, 100)
	subMonthly = sm

	sl := lifetime.NewLifetimeSubscription(1000)
	subLifetime = sl

	newsletterVisble = false
}

func Render(path string) string {
	out := md.H1("Welcome to the world!\n\n")

	out += md.Image("avatar", avatar)
	out += md.Link("Github: kazai777", githubLink) + "\n\n"

	out += md.H2("About me")
	out += md.HorizontalRule()

	out += md.H2("My last realization")
	out += md.HorizontalRule()

	out += md.H2("Newsletter")
	out += md.HorizontalRule()
	out += md.Paragraph("Welcome to my newsletter, by subscribing to this one you'll get all the information before anyone else!\n\n")
	out += md.Bold("Subscribe :")
	out += md.Link(" 1 month |", txlink.Call("SubscribeMonthly"))
	out += md.Link(" Lifetime", txlink.Call("SubscribeLifetime")) + "\n\n"
	out += md.Bold("Offer :")
	out += md.Link(" 1 month |", txlink.Call("SubscribeLifetime"))
	out += md.Link(" Lifetime", txlink.Call("SubscribeLifetime")) + "\n\n"

	if newsletterVisble {
		out += RenderNewsletter()
	} else {
		out += md.Paragraph(md.Link("Show Newsletter", txlink.Call("ShowNewsletter")))
	}
	return out
}

func RenderNewsletter() string {
	return "Welcome newsletter premium member"
}

func ShowNewsletter() string {
	caller := std.PrevRealm().Addr()

	if hasAnyValidSubscription(caller) {
		newsletterVisble = true
		return ufmt.Sprintf("Welcome back")
	} else {
		return "please subscribe for show the newsletter"
	}
}

func SubscribeMonthly() {
	err := subMonthly.Subscribe()
	if err != nil {
		panic(err)
	}
}

func SubscribeLifetime() {
	err := subLifetime.Subscribe()
	if err != nil {
		panic(err)
	}
}

func GiftMonthly(receiver std.Address) {
	err := subMonthly.(interface {
		GiftSubscription(std.Address) error
	}).GiftSubscription(receiver)

	if err != nil {
		panic(err)
	}
}

func GiftLifetime(receiver std.Address) {
	err := subLifetime.(interface {
		GiftSubscription(std.Address) error
	}).GiftSubscription(receiver)

	if err != nil {
		panic(err)
	}
}

func hasAnyValidSubscription(addr std.Address) bool {
    // Vérifier dans la formule mensuelle
    if err := subMonthly.HasValidSubscription(addr); err == nil {
        return true
    }
    // Vérifier dans la formule lifetime
    if err := subLifetime.HasValidSubscription(addr); err == nil {
        return true
    }
    return false
}

