package httpapi

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/oapi-codegen/nullable"

	cestasync "github.com/tsantanadev/cesta/backend/internal/sync"
)

// PushMutations applies a batch of the signed-in User's outbox mutations.
func (s *Server) PushMutations(ctx context.Context, req PushMutationsRequestObject) (PushMutationsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	if req.Body == nil {
		return PushMutations400JSONResponse{BadRequestJSONResponse{Code: ApiErrorCodeInvalidRequest, Message: "request body is required"}}, nil
	}
	ms := make([]cestasync.Mutation, 0, len(req.Body.Mutations))
	for _, m := range req.Body.Mutations {
		ms = append(ms, syncMutation(m))
	}
	results, err := s.Sync.Push(ctx, u.ID, ms)
	if errors.Is(err, cestasync.ErrInvalidBatch) {
		return PushMutations400JSONResponse{BadRequestJSONResponse{
			Code:    ApiErrorCodeInvalidRequest,
			Message: fmt.Sprintf("a push carries 1 to %d mutations, each with an id", cestasync.MaxBatch),
		}}, nil
	}
	if err != nil {
		return nil, err
	}
	out := PushMutations200JSONResponse{Results: make([]MutationResult, 0, len(results))}
	for _, r := range results {
		out.Results = append(out.Results, apiMutationResult(r))
	}
	return out, nil
}

// PullChanges returns the changes since the cursor that the signed-in User can see.
func (s *Server) PullChanges(ctx context.Context, req PullChangesRequestObject) (PullChangesResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	var cursor string
	if req.Params.Cursor != nil {
		cursor = *req.Params.Cursor
	}
	limit := 0
	if req.Params.Limit != nil {
		limit = *req.Params.Limit
		if limit == 0 {
			limit = -1 // an explicit 0 is out of range, not the default
		}
	}
	ch, err := s.Sync.Pull(ctx, u.ID, cursor, limit)
	switch {
	case errors.Is(err, cestasync.ErrInvalidCursor):
		return PullChanges400JSONResponse{BadRequestJSONResponse{Code: ApiErrorCodeInvalidRequest, Message: "the cursor is not valid"}}, nil
	case errors.Is(err, cestasync.ErrInvalidLimit):
		return PullChanges400JSONResponse{BadRequestJSONResponse{
			Code:    ApiErrorCodeInvalidRequest,
			Message: fmt.Sprintf("limit must be 1 to %d", cestasync.MaxPullLimit),
		}}, nil
	case err != nil:
		return nil, err
	}
	out := PullChanges200JSONResponse{
		Items:      make([]Item, 0, len(ch.Items)),
		Tombstones: make([]Tombstone, 0, len(ch.Tombstones)),
		Cursor:     ch.Cursor,
		HasMore:    ch.HasMore,
	}
	for _, it := range ch.Items {
		out.Items = append(out.Items, apiItem(it))
	}
	for _, t := range ch.Tombstones {
		ts := Tombstone{Type: TombstoneType(t.Type), Id: t.ID}
		if t.Type == cestasync.TombstoneItem {
			ts.ListId = &t.ListID
		}
		out.Tombstones = append(out.Tombstones, ts)
	}
	return out, nil
}

func syncMutation(m Mutation) cestasync.Mutation {
	out := cestasync.Mutation{
		ID:              m.Id,
		Type:            cestasync.MutationType(m.Type),
		EntityID:        m.EntityId,
		ClientTimestamp: m.ClientTimestamp,
	}
	if m.ListId != nil {
		out.ListID = *m.ListId
	}
	if f := m.Fields; f != nil {
		out.Fields = cestasync.Fields{
			Name:     f.Name,
			Quantity: field(f.Quantity, func(v string) string { return v }),
			Unit:     field(f.Unit, func(v ItemFieldsUnit) string { return string(v) }),
			Note:     field(f.Note, func(v string) string { return v }),
			Checked:  f.Checked,
		}
	}
	return out
}

func field[T any](n nullable.Nullable[T], conv func(T) string) cestasync.Field[string] {
	if !n.IsSpecified() {
		return cestasync.Field[string]{}
	}
	if n.IsNull() {
		return cestasync.Field[string]{Present: true}
	}
	v := conv(n.MustGet())
	return cestasync.Field[string]{Present: true, Value: &v}
}

func apiMutationResult(r cestasync.Result) MutationResult {
	if r.Applied {
		return MutationResult{MutationId: r.MutationID, Status: Applied}
	}
	reason := ApiError{Code: ApiErrorCode(r.Reason), Message: r.Message}
	if r.Limit > 0 {
		limit := r.Limit
		reason.Limit = &limit
	}
	return MutationResult{MutationId: r.MutationID, Status: Rejected, Reason: &reason}
}

// checkedByRef is the type the generated Item uses for checkedBy.
type checkedByRef = struct {
	DisplayName string    `json:"displayName"`
	Id          uuid.UUID `json:"id"` //nolint:revive // must match the generated field name
}

func apiItem(it cestasync.Item) Item {
	out := Item{
		Id:        it.ID,
		ListId:    it.ListID,
		Name:      it.Name,
		AddedBy:   UserRef{Id: it.AddedBy.ID, DisplayName: it.AddedBy.DisplayName},
		AddedAt:   it.AddedAt,
		UpdatedAt: it.UpdatedAt,
		Quantity:  orNull(it.Quantity),
		Note:      orNull(it.Note),
		CheckedAt: orNull(it.CheckedAt),
		Unit:      nullable.NewNullNullable[ItemUnit](),
		CheckedBy: nullable.NewNullNullable[checkedByRef](),
	}
	if it.Unit != nil {
		out.Unit = nullable.NewNullableWithValue(ItemUnit(*it.Unit))
	}
	if it.CheckedBy != nil {
		out.CheckedBy = nullable.NewNullableWithValue(checkedByRef{Id: it.CheckedBy.ID, DisplayName: it.CheckedBy.DisplayName})
	}
	return out
}

// orNull returns v as a value that is always sent: null when v is nil.
func orNull[T any](v *T) nullable.Nullable[T] {
	if v == nil {
		return nullable.NewNullNullable[T]()
	}
	return nullable.NewNullableWithValue(*v)
}
