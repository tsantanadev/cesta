package httpapi

import (
	"context"
	"errors"
	"fmt"
	"net/http"

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
	if err != nil {
		status, apiErr, ok := invitationError(err)
		switch {
		case !ok:
			return nil, err
		case status == http.StatusBadRequest:
			return CreateInvitation400JSONResponse{BadRequestJSONResponse(apiErr)}, nil
		case status == http.StatusForbidden:
			return CreateInvitation403JSONResponse{ForbiddenJSONResponse(apiErr)}, nil
		case status == http.StatusNotFound:
			return CreateInvitation404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		default:
			return CreateInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
		}
	}
	return CreateInvitation201JSONResponse(apiInvitation(inv)), nil
}

// ListListInvitations returns the pending Invitations to a List the signed-in User owns.
func (s *Server) ListListInvitations(ctx context.Context, req ListListInvitationsRequestObject) (ListListInvitationsResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	invs, err := s.Sharing.ForList(ctx, u.ID, req.ListId)
	if err != nil {
		status, apiErr, ok := invitationError(err)
		switch {
		case !ok:
			return nil, err
		case status == http.StatusForbidden:
			return ListListInvitations403JSONResponse{ForbiddenJSONResponse(apiErr)}, nil
		case status == http.StatusNotFound:
			return ListListInvitations404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		default:
			return ListListInvitations409JSONResponse{ConflictJSONResponse(apiErr)}, nil
		}
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
	if err != nil {
		status, apiErr, ok := invitationError(err)
		switch {
		case !ok:
			return nil, err
		case status == http.StatusForbidden:
			return CancelInvitation403JSONResponse{ForbiddenJSONResponse(apiErr)}, nil
		case status == http.StatusNotFound:
			return CancelInvitation404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		default:
			return CancelInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
		}
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
	if err != nil {
		if _, apiErr, ok := invitationError(err); ok {
			return LookupInvitation404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		}
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
	if err != nil {
		status, apiErr, ok := invitationError(err)
		switch {
		case !ok:
			return nil, err
		case status == http.StatusNotFound:
			return AcceptInvitation404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		default:
			return AcceptInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
		}
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
	if err != nil {
		status, apiErr, ok := invitationError(err)
		switch {
		case !ok:
			return nil, err
		case status == http.StatusNotFound:
			return DeclineInvitation404JSONResponse{NotFoundJSONResponse(apiErr)}, nil
		default:
			return DeclineInvitation409JSONResponse{ConflictJSONResponse(apiErr)}, nil
		}
	}
	return DeclineInvitation200JSONResponse(apiInvitation(inv)), nil
}

// invitationError returns the HTTP status and API error for an error from
// package sharing, or ok false for an unexpected one.
func invitationError(err error) (status int, apiErr ApiError, ok bool) {
	conflict := func(code ApiErrorCode, msg string) (int, ApiError, bool) {
		return http.StatusConflict, ApiError{Code: code, Message: msg}, true
	}
	switch {
	case errors.Is(err, sharing.ErrInvalidEmail):
		return http.StatusBadRequest, ApiError{Code: ApiErrorCodeInvalidEmail, Message: "not a valid email address"}, true
	case errors.Is(err, sharing.ErrNotFound):
		return http.StatusNotFound, ApiError{Code: ApiErrorCodeInvitationNotFound, Message: "no such Invitation"}, true
	case errors.Is(err, sharing.ErrCancelled):
		return conflict(ApiErrorCodeInvitationCancelled, "the Owner cancelled this Invitation")
	case errors.Is(err, sharing.ErrDeclined):
		return conflict(ApiErrorCodeInvitationDeclined, "this Invitation was declined")
	case errors.Is(err, sharing.ErrExpired):
		return conflict(ApiErrorCodeInvitationExpired,
			fmt.Sprintf("this Invitation expired %d days after it was sent", int(sharing.ExpiresAfter.Hours()/24)))
	case errors.Is(err, sharing.ErrAccepted):
		return conflict(ApiErrorCodeInvitationAccepted, "this Invitation was already accepted")
	case errors.Is(err, sharing.ErrLimitReached):
		limit := sharing.MaxPerDay
		return http.StatusConflict, ApiError{
			Code:    ApiErrorCodeLimitExceeded,
			Message: fmt.Sprintf("the User already sent the limit of %d Invitations in 24 hours", limit),
			Limit:   &limit,
		}, true
	case errors.Is(err, membership.ErrListFull):
		limit := membership.DefaultMaxPerList
		return http.StatusConflict, ApiError{
			Code:    ApiErrorCodeListFull,
			Message: fmt.Sprintf("the List already has the limit of %d Members", limit),
			Limit:   &limit,
		}, true
	case errors.Is(err, lists.ErrNotFound):
		return http.StatusNotFound, listNotFound(), true
	case errors.Is(err, lists.ErrNotOwner):
		return http.StatusForbidden, notListOwner(), true
	case errors.Is(err, lists.ErrDeleted):
		return http.StatusConflict, listDeleted(), true
	}
	return 0, ApiError{}, false
}

func invitee(u identity.User) sharing.Invitee {
	return sharing.Invitee{ID: u.ID, Email: u.Email}
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
		Email:     inv.Email,
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
