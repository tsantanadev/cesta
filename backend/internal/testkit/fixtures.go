package testkit

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
)

// AddEditor makes id an Editor of the List listID, as if they had accepted an
// Invitation. No endpoint can do this until Invitations and Share links exist
// (#9, #10); replace calls to it with those flows then.
func (s *Server) AddEditor(t testing.TB, listID string, id auth.Identity) {
	t.Helper()
	res := s.As(id).Get(t, "/api/me")
	res.RequireStatus(t, http.StatusOK)
	var me struct {
		ID uuid.UUID `json:"id"`
	}
	if err := json.Unmarshal(res.Body, &me); err != nil {
		t.Fatalf("testkit: decode User: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	members := membership.NewService(s.deps.DB)
	if err := members.Grant(ctx, s.deps.DB, uuid.MustParse(listID), me.ID, membership.Editor, s.Clock.Now()); err != nil {
		t.Fatalf("testkit: add Editor: %v", err)
	}
}
