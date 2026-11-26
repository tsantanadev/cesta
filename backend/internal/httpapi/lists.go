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
	case errors.Is(err, lists.ErrDeleted):
		return CreateList409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case err != nil:
		return nil, err
	case created:
		return CreateList201JSONResponse(apiListSummary(l)), nil
	default:
		return CreateList200JSONResponse(apiListSummary(l)), nil
	}
}

// RenameList renames a List the signed-in User owns.
func (s *Server) RenameList(ctx context.Context, req RenameListRequestObject) (RenameListResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	if req.Body == nil {
		return RenameList400JSONResponse{BadRequestJSONResponse{Code: ApiErrorCodeInvalidRequest, Message: "request body is required"}}, nil
	}
	l, err := s.Lists.Rename(ctx, u.ID, req.ListId, req.Body.Name)
	switch {
	case errors.Is(err, lists.ErrInvalidName):
		return RenameList400JSONResponse{BadRequestJSONResponse(invalidListName())}, nil
	case errors.Is(err, lists.ErrNotFound):
		return RenameList404JSONResponse{NotFoundJSONResponse(listNotFound())}, nil
	case errors.Is(err, lists.ErrNotOwner):
		return RenameList403JSONResponse{ForbiddenJSONResponse(notListOwner())}, nil
	case errors.Is(err, lists.ErrDeleted):
		return RenameList409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case err != nil:
		return nil, err
	}
	return RenameList200JSONResponse(apiListSummary(l)), nil
}

// DeleteList deletes a List the signed-in User owns.
func (s *Server) DeleteList(ctx context.Context, req DeleteListRequestObject) (DeleteListResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	d, err := s.Lists.Delete(ctx, u.ID, req.ListId)
	switch {
	case errors.Is(err, lists.ErrNotFound):
		return DeleteList404JSONResponse{NotFoundJSONResponse(listNotFound())}, nil
	case errors.Is(err, lists.ErrNotOwner):
		return DeleteList403JSONResponse{ForbiddenJSONResponse(notListOwner())}, nil
	case err != nil:
		return nil, err
	}
	return DeleteList200JSONResponse(apiDeletedList(d)), nil
}

func (s *Server) RestoreList(context.Context, RestoreListRequestObject) (RestoreListResponseObject, error) {
	return nil, errListsNotImplemented
}

// ListDeletedLists returns the Lists the signed-in User deleted and can still restore.
func (s *Server) ListDeletedLists(ctx context.Context, _ ListDeletedListsRequestObject) (ListDeletedListsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	deleted, err := s.Lists.RecentlyDeleted(ctx, u.ID)
	if err != nil {
		return nil, err
	}
	out := ListDeletedLists200JSONResponse{Lists: make([]DeletedList, 0, len(deleted))}
	for _, d := range deleted {
		out.Lists = append(out.Lists, apiDeletedList(d))
	}
	return out, nil
}

var errListsNotImplemented = errors.New("lists: not implemented")

func invalidListName() ApiError {
	return ApiError{
		Code:    ApiErrorCodeInvalidListName,
		Message: fmt.Sprintf("List name must be 1 to %d visible characters", lists.MaxNameLength),
	}
}

func listDeleted() ApiError {
	return ApiError{Code: ApiErrorCodeListDeleted, Message: "the List is deleted; restore it first"}
}

func apiDeletedList(d lists.Deleted) DeletedList {
	return DeletedList{Id: d.ID, Name: d.Name, DeletedAt: d.DeletedAt, PurgeAt: d.PurgeAt}
}

func listNotFound() ApiError {
	return ApiError{Code: ApiErrorCodeListNotFound, Message: "no such List"}
}

func notListOwner() ApiError {
	return ApiError{Code: ApiErrorCodeNotListOwner, Message: "only the List's Owner can do this"}
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
