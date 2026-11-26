package httpapi

import (
	"context"
	"errors"
	"fmt"

	"github.com/tsantanadev/cesta/backend/internal/lists"
)

// ListLists returns the Lists the signed-in User is a Member of.
func (s *Server) ListLists(ctx context.Context, _ ListListsRequestObject) (ListListsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	mine, err := s.Lists.Mine(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	out := ListLists200JSONResponse{Lists: make([]ListSummary, 0, len(mine))}
	for _, l := range mine {
		out.Lists = append(out.Lists, apiListSummary(l))
	}
	return out, nil
}

// CreateList creates a List owned by the signed-in User, or returns it on a retry.
func (s *Server) CreateList(ctx context.Context, req CreateListRequestObject) (CreateListResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	if req.Body == nil {
		return CreateList400JSONResponse{BadRequestJSONResponse{Code: ApiErrorCodeInvalidRequest, Message: "request body is required"}}, nil
	}
	l, created, err := s.Lists.Create(ctx, u.ID, req.Body.Id, req.Body.Name)
	switch {
	case errors.Is(err, lists.ErrInvalidName):
		return CreateList400JSONResponse{BadRequestJSONResponse(invalidListName())}, nil
	case errors.Is(err, lists.ErrIDTaken):
		return CreateList409JSONResponse{ConflictJSONResponse{Code: ApiErrorCodeListIdTaken, Message: "another List has this id"}}, nil
	case errors.Is(err, lists.ErrLimitReached):
		return CreateList409JSONResponse{ConflictJSONResponse(limitExceeded())}, nil
	case err != nil:
		return nil, err
	case created:
		return CreateList201JSONResponse(apiListSummary(l)), nil
	default:
		return CreateList200JSONResponse(apiListSummary(l)), nil
	}
}

func (s *Server) RenameList(context.Context, RenameListRequestObject) (RenameListResponseObject, error) {
	return nil, errListsNotImplemented
}

func (s *Server) DeleteList(context.Context, DeleteListRequestObject) (DeleteListResponseObject, error) {
	return nil, errListsNotImplemented
}

func (s *Server) RestoreList(context.Context, RestoreListRequestObject) (RestoreListResponseObject, error) {
	return nil, errListsNotImplemented
}

func (s *Server) ListDeletedLists(context.Context, ListDeletedListsRequestObject) (ListDeletedListsResponseObject, error) {
	return nil, errListsNotImplemented
}

var errListsNotImplemented = errors.New("lists: not implemented")

func invalidListName() ApiError {
	return ApiError{
		Code:    ApiErrorCodeInvalidListName,
		Message: fmt.Sprintf("List name must be 1 to %d visible characters", lists.MaxNameLength),
	}
}

func limitExceeded() ApiError {
	return ApiError{Code: ApiErrorCodeLimitExceeded, Message: "the User already owns the most Lists allowed"}
}

func apiListSummary(l lists.Summary) ListSummary {
	return ListSummary{
		Id:                 l.ID,
		Name:               l.Name,
		Role:               Role(l.Role),
		UncheckedItemCount: 0, // Items arrive with #7
		MemberCount:        l.MemberCount,
		CreatedAt:          l.CreatedAt,
	}
}
