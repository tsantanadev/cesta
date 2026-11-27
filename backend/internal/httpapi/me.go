package httpapi

import (
	"context"
	"errors"
	"fmt"

	"github.com/tsantanadev/cesta/backend/internal/identity"
)

// GetMe returns the signed-in User.
func (s *Server) GetMe(ctx context.Context, _ GetMeRequestObject) (GetMeResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	return GetMe200JSONResponse(apiUser(u)), nil
}

// UpdateMe sets the signed-in User's display name.
func (s *Server) UpdateMe(ctx context.Context, req UpdateMeRequestObject) (UpdateMeResponseObject, error) {
	u, err := signedIn(ctx)
	if err != nil {
		return nil, err
	}
	if req.Body == nil {
		return UpdateMe400JSONResponse{BadRequestJSONResponse{Code: ApiErrorCodeInvalidRequest, Message: "request body is required"}}, nil
	}
	u, err = s.Identity.SetDisplayName(ctx, u.ID, req.Body.DisplayName)
	if errors.Is(err, identity.ErrInvalidDisplayName) {
		return UpdateMe400JSONResponse{BadRequestJSONResponse{
			Code:    ApiErrorCodeInvalidDisplayName,
			Message: fmt.Sprintf("display name must be 1 to %d visible characters", identity.MaxDisplayNameLength),
		}}, nil
	}
	if err != nil {
		return nil, err
	}
	return UpdateMe200JSONResponse(apiUser(u)), nil
}

// signedIn returns the User the authenticate middleware put in ctx. Its absence
// on an operation that requires auth is a wiring bug, not a client error.
func signedIn(ctx context.Context) (identity.User, error) {
	u, ok := identity.FromContext(ctx)
	if !ok {
		return identity.User{}, errors.New("httpapi: no signed-in User in context")
	}
	return u, nil
}

func apiUser(u identity.User) User {
	return User{Id: u.ID, Email: u.Email, DisplayName: u.DisplayName, DisplayNameConfirmed: u.DisplayNameConfirmed}
}
