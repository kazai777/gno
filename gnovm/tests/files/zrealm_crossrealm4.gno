// PKGPATH: gno.land/r/crossrealm
package crossrealm

import (
	"gno.land/r/demo/tests"
)

// NOTE: it is valid to persist a pointer to an external object
var somevalue *tests.TestRealmObject

func init() {
	somevalue = &tests.TestRealmObjectValue
}

func main(cur realm) {
	// NOTE: it is valid to modify it using the external realm function.
	somevalue.Modify()
	println(somevalue)
}

// Output:
// readonly(&(struct{("_modified" string)} gno.land/r/demo/tests.TestRealmObject))
