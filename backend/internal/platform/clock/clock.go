// Package clock abstracts the current time so tests can control it.
package clock

import "time"

// Clock tells the current time. Code that needs "now" takes a Clock instead of
// calling time.Now, so tests can advance time across the 7, 14 and 30 day windows.
type Clock interface {
	Now() time.Time
}

// System is the real wall clock, in UTC.
type System struct{}

// Now returns the current UTC time.
func (System) Now() time.Time { return time.Now().UTC() }
