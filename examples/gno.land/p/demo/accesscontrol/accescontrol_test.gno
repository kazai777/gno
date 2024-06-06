package accesscontrol

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"
)

// TestNewRoleData tests the creation of a new RoleData instance
func TestNewRoleData(t *testing.T) {
	admin := testutils.TestAddress("g1admin")
	roleData := NewRoleData(admin)
	if roleData.adminRole != admin {
		t.Fatalf("expected admin role %s, got %s", admin, roleData.adminRole)
	}
	// if !roleData.hasRole.IsEmpty() {
	// 	t.Fatalf("expected empty role tree, got non-empty")
	// }
}

// TestGrantRole tests the GrantRole method
func TestGrantRole(t *testing.T) {
	admin := testutils.TestAddress("g1admin")
	roleData := NewRoleData(admin)
	roleData.GrantRole(admin)

	if !roleData.HasRole(admin) {
		t.Fatalf("expected admin to have role, but does not")
	}
}

// TestRevokeRole tests the RevokeRole method
func TestRevokeRole(t *testing.T) {
	admin := testutils.TestAddress("g1admin")
	roleData := NewRoleData(admin)
	roleData.GrantRole(admin)
	roleData.RevokeRole(admin)

	if roleData.HasRole(admin) {
		t.Fatalf("expected admin role to be revoked, but still has role")
	}
}

// TestRenounceRole tests the RenounceRole method
func TestRenounceRole(t *testing.T) {
	admin := testutils.TestAddress("g1admin")
	roleData := NewRoleData(admin)
	roleData.GrantRole(admin)
	roleData.RenounceRole(admin)

	if roleData.HasRole(admin) {
		t.Fatalf("expected admin role to be renounced, but still has role")
	}
}

// TestSetRoleAdmin tests the SetRoleAdmin method
func TestSetRoleAdmin(t *testing.T) {
	admin := testutils.TestAddress("g1admin")
	newAdmin := testutils.TestAddress("g1newadmin")
	roleData := NewRoleData(admin)
	roleData.SetRoleAdmin(newAdmin)

	if roleData.adminRole != newAdmin {
		t.Fatalf("expected new admin role %s, got %s", newAdmin, roleData.adminRole)
	}
}
