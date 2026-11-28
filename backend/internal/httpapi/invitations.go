package httpapi

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"github.com/google/uuid"

	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/lists"
	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/notify"
	"github.com/tsantanadev/cesta/backend/internal/sharing"
)

// CreateInvitation invites an email address to a List the signed-in User owns.
func (s *Server) CreateInvitation(ctx context.Context, req CreateInvitationRequestObject) (CreateInvitationResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	if req.Body == nil || !req.Body.Language.Valid() {
		return CreateInvitation400JSONResponse{BadRequestJSONResponse(invalidRequest())}, nil
	}
	inv, err := s.Sharing.Create(ctx, u.ID, req.ListId, req.Body.Email, notify.Language(req.Body.Language))
	switch {
	case errors.Is(err, sharing.ErrInvalidEmail):
		return CreateInvitation400JSONResponse{BadRequestJSONResponse(invalidEmail())}, nil
	case errors.Is(err, lists.ErrNotFound):
		return CreateInvitation404JSONResponse{NotFoundJSONResponse(listNotFound())}, nil
	case errors.Is(err, lists.ErrNotOwner):
		return CreateInvitation403JSONResponse{ForbiddenJSONResponse(notListOwner())}, nil
	case errors.Is(err, lists.ErrDeleted):
		return CreateInvitation409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case errors.Is(err, sharing.ErrAlreadyMember):
		return CreateInvitation409JSONResponse{ConflictJSONResponse(alreadyMember())}, nil
	case errors.Is(err, sharing.ErrLimitReached):
		return CreateInvitation409JSONResponse{ConflictJSONResponse(
			limitExceeded(sharing.MaxPerDay, "the User already sent the limit of %d Invitations in 24 hours"))}, nil
	case errors.Is(err, sharing.ErrNotSent):
		// The cause (the provider's error) is only logged.
		s.Logger.ErrorContext(ctx, "invitation email not sent", slog.String("error", err.Error()))
		return CreateInvitation502JSONResponse{EmailNotSentJSONResponse(emailNotSent())}, nil
	case err != nil:
		return nil, err
	}
	return CreateInvitation201JSONResponse(apiInvitation(inv)), nil
}

// ListListInvitations returns the open Invitations to a List the signed-in User owns.
func (s *Server) ListListInvitations(ctx context.Context, req ListListInvitationsRequestObject) (ListListInvitationsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	invs, err := s.Sharing.ForList(ctx, u.ID, req.ListId)
	switch {
	case errors.Is(err, lists.ErrNotFound):
		return ListListInvitations404JSONResponse{NotFoundJSONResponse(listNotFound())}, nil
	case errors.Is(err, lists.ErrNotOwner):
		return ListListInvitations403JSONResponse{ForbiddenJSONResponse(notListOwner())}, nil
	case errors.Is(err, lists.ErrDeleted):
		return ListListInvitations409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case err != nil:
		return nil, err
	}
	return ListListInvitations200JSONResponse(apiInvitations(invs)), nil
}

// CancelInvitation cancels an Invitation to a List the signed-in User owns.
func (s *Server) CancelInvitation(ctx context.Context, req CancelInvitationRequestObject) (CancelInvitationResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	inv, err := s.Sharing.Cancel(ctx, u.ID, req.ListId, req.InvitationId)
	if apiErr, ok := invitationClosed(err); ok {
		return CancelInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
	}
	switch {
	case errors.Is(err, sharing.ErrNotFound):
		return CancelInvitation404JSONResponse{NotFoundJSONResponse(invitationNotFound())}, nil
	case errors.Is(err, lists.ErrNotFound):
		return CancelInvitation404JSONResponse{NotFoundJSONResponse(listNotFound())}, nil
	case errors.Is(err, lists.ErrNotOwner):
		return CancelInvitation403JSONResponse{ForbiddenJSONResponse(notListOwner())}, nil
	case errors.Is(err, lists.ErrDeleted):
		return CancelInvitation409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case err != nil:
		return nil, err
	}
	return CancelInvitation200JSONResponse(apiInvitation(inv)), nil
}

// ListMyInvitations returns the pending Invitations addressed to the signed-in User's email.
func (s *Server) ListMyInvitations(ctx context.Context, _ ListMyInvitationsRequestObject) (ListMyInvitationsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	invs, err := s.Sharing.ForUser(ctx, invitee(u))
	if err != nil {
		return nil, err
	}
	return ListMyInvitations200JSONResponse(apiInvitations(invs)), nil
}

// LookupInvitation returns the Invitation a token (or id) identifies.
func (s *Server) LookupInvitation(ctx context.Context, req LookupInvitationRequestObject) (LookupInvitationResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	ref, ok := invitationRef(req.Body)
	if !ok {
		return LookupInvitation400JSONResponse{BadRequestJSONResponse(invalidInvitationRef())}, nil
	}
	inv, err := s.Sharing.Lookup(ctx, invitee(u), ref)
	switch {
	case errors.Is(err, sharing.ErrNotFound):
		return LookupInvitation404JSONResponse{NotFoundJSONResponse(invitationNotFound())}, nil
	case err != nil:
		return nil, err
	}
	return LookupInvitation200JSONResponse(apiInvitation(inv)), nil
}

// AcceptInvitation makes the signed-in User an Editor of the Invitation's List.
func (s *Server) AcceptInvitation(ctx context.Context, req AcceptInvitationRequestObject) (AcceptInvitationResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	ref, ok := invitationRef(req.Body)
	if !ok {
		return AcceptInvitation400JSONResponse{BadRequestJSONResponse(invalidInvitationRef())}, nil
	}
	listID, err := s.Sharing.Accept(ctx, invitee(u), ref)
	if apiErr, ok := invitationClosed(err); ok {
		return AcceptInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
	}
	switch {
	case errors.Is(err, sharing.ErrNotFound):
		return AcceptInvitation404JSONResponse{NotFoundJSONResponse(invitationNotFound())}, nil
	case errors.Is(err, lists.ErrDeleted):
		return AcceptInvitation409JSONResponse{ConflictJSONResponse(listDeleted())}, nil
	case errors.Is(err, membership.ErrListFull):
		return AcceptInvitation409JSONResponse{ConflictJSONResponse(listFull())}, nil
	case err != nil:
		return nil, err
	}
	l, err := s.Lists.Get(ctx, u.ID, listID)
	if err != nil {
		return nil, err
	}
	sum, err := s.listSummary(ctx, l)
	if err != nil {
		return nil, err
	}
	return AcceptInvitation200JSONResponse(sum), nil
}

// DeclineInvitation declines an Invitation.
func (s *Server) DeclineInvitation(ctx context.Context, req DeclineInvitationRequestObject) (DeclineInvitationResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	ref, ok := invitationRef(req.Body)
	if !ok {
		return DeclineInvitation400JSONResponse{BadRequestJSONResponse(invalidInvitationRef())}, nil
	}
	inv, err := s.Sharing.Decline(ctx, invitee(u), ref)
	if apiErr, ok := invitationClosed(err); ok {
		return DeclineInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
	}
	switch {
	case errors.Is(err, sharing.ErrNotFound):
		return DeclineInvitation404JSONResponse{NotFoundJSONResponse(invitationNotFound())}, nil
	case err != nil:
		return nil, err
	}
	return DeclineInvitation200JSONResponse(apiInvitation(inv)), nil
}

// invitationClosed returns the API error for acting on an Invitation that is
// no longer pending, or ok false for any other error.
func invitationClosed(err error) (apiErr ApiError, ok bool) {
	switch {
	case errors.Is(err, sharing.ErrCancelled):
		return ApiError{Code: ApiErrorCodeInvitationCancelled, Message: "the Owner cancelled this Invitation"}, true
	case errors.Is(err, sharing.ErrDeclined):
		return ApiError{Code: ApiErrorCodeInvitationDeclined, Message: "this Invitation was declined"}, true
	case errors.Is(err, sharing.ErrExpired):
		return ApiError{
			Code:    ApiErrorCodeInvitationExpired,
			Message: fmt.Sprintf("this Invitation expired %d days after it was sent", int(sharing.ExpiresAfter.Hours()/24)),
		}, true
	case errors.Is(err, sharing.ErrAccepted):
		return ApiError{Code: ApiErrorCodeInvitationAccepted, Message: "this Invitation was already accepted"}, true
	}
	return ApiError{}, false
}

func invalidEmail() ApiError {
	return ApiError{Code: ApiErrorCodeInvalidEmail, Message: "not a valid email address"}
}

func invitationNotFound() ApiError {
	return ApiError{Code: ApiErrorCodeInvitationNotFound, Message: "no such Invitation"}
}

func alreadyMember() ApiError {
	return ApiError{Code: ApiErrorCodeAlreadyMember, Message: "this address belongs to a Member of the List"}
}

func emailNotSent() ApiError {
	return ApiError{Code: ApiErrorCodeEmailNotSent, Message: "the Invitation email couldn't be sent; try again"}
}

func listFull() ApiError {
	limit := membership.MaxPerList
	return ApiError{
		Code:    ApiErrorCodeListFull,
		Message: fmt.Sprintf("the List already has the limit of %d Members", limit),
		Limit:   &limit,
	}
}

func invitee(u identity.User) sharing.Invitee {
	return sharing.Invitee{ID: u.ID, Email: sharing.CanonicalEmail(u.Email)}
}

// invitationRef reads an InvitationRef with exactly one of token or id.
func invitationRef(body *InvitationRef) (sharing.Ref, bool) {
	if body == nil {
		return sharing.Ref{}, false
	}
	var ref sharing.Ref
	if body.Token != nil {
		ref.Token = *body.Token
	}
	if body.Id != nil {
		ref.ID = *body.Id
	}
	if (ref.Token == "") == (ref.ID == uuid.Nil) {
		return sharing.Ref{}, false
	}
	return ref, true
}

func invalidRequest() ApiError {
	return ApiError{Code: ApiErrorCodeInvalidRequest, Message: "the request is malformed"}
}

func invalidInvitationRef() ApiError {
	return ApiError{Code: ApiErrorCodeInvalidRequest, Message: "send exactly one of token or id"}
}

func apiInvitation(inv sharing.Invitation) Invitation {
	return Invitation{
		Id:        inv.ID,
		ListId:    inv.ListID,
		ListName:  inv.ListName,
		Email:     string(inv.Email),
		InvitedBy: UserRef{Id: inv.InvitedBy, DisplayName: inv.InviterName},
		Status:    InvitationStatus(inv.Status),
		CreatedAt: inv.CreatedAt,
		ExpiresAt: inv.ExpiresAt,
	}
}

func apiInvitations(invs []sharing.Invitation) Invitations {
	out := Invitations{Invitations: make([]Invitation, 0, len(invs))}
	for _, inv := range invs {
		out.Invitations = append(out.Invitations, apiInvitation(inv))
	}
	return out
}
