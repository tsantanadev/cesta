package httpapi

import (
	"context"
	"errors"
)

// Placeholder handlers for the Lists endpoints (#6). The lists and membership
// modules replace these; until then every call fails with 500.
var errListsNotImplemented = errors.New("lists: not implemented")

func (s *Server) ListLists(context.Context, ListListsRequestObject) (ListListsResponseObject, error) {
	return nil, errListsNotImplemented
}

func (s *Server) CreateList(context.Context, CreateListRequestObject) (CreateListResponseObject, error) {
	return nil, errListsNotImplemented
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
