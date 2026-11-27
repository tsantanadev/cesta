// Package ratelimit is an in-memory, per-key token bucket limiter.
//
// Buckets live in the process, so with N instances the effective limit is up to
// N times the configured one. That is accepted: the limiter exists to protect the
// bill and the database from floods, not to meter exact quotas.
package ratelimit

import (
	"fmt"
	"math"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
)

// Rule allows Burst requests at once, refilling one request every Every.
type Rule struct {
	Burst int
	Every time.Duration
}

// ParseRule reads a Rule written as "<burst>/<every>", e.g. "120/250ms": a
// burst of 120 requests, refilling one every 250ms.
func ParseRule(s string) (Rule, error) {
	burst, every, ok := strings.Cut(s, "/")
	b, errB := strconv.Atoi(burst)
	e, errE := time.ParseDuration(every)
	if !ok || errB != nil || errE != nil || b <= 0 || e <= 0 {
		return Rule{}, fmt.Errorf("rate limit %q: want <burst>/<every> with both positive, e.g. 120/250ms", s)
	}
	return Rule{Burst: b, Every: e}, nil
}

// sweepInterval is how often idle, full buckets are dropped so memory stays bounded.
const sweepInterval = time.Minute

// Limiter tracks one bucket per key.
type Limiter struct {
	rule  Rule
	clock clock.Clock

	mu        sync.Mutex
	buckets   map[string]*bucket
	lastSweep time.Time
}

type bucket struct {
	tokens float64
	at     time.Time
}

// New returns a Limiter applying rule to every key.
func New(rule Rule, c clock.Clock) *Limiter {
	return &Limiter{rule: rule, clock: c, buckets: map[string]*bucket{}, lastSweep: c.Now()}
}

// Allow takes one request from key's bucket. When the bucket is empty it
// returns false and how long until the next request would be allowed.
func (l *Limiter) Allow(key string) (bool, time.Duration) {
	now := l.clock.Now()
	l.mu.Lock()
	defer l.mu.Unlock()
	l.sweep(now)

	b, ok := l.buckets[key]
	if !ok {
		b = &bucket{tokens: float64(l.rule.Burst), at: now}
		l.buckets[key] = b
	}
	b.tokens = l.refilled(b, now)
	b.at = now
	if b.tokens >= 1 {
		b.tokens--
		return true, 0
	}
	wait := time.Duration(math.Ceil((1 - b.tokens) * float64(l.rule.Every)))
	return false, wait
}

func (l *Limiter) refilled(b *bucket, now time.Time) float64 {
	elapsed := now.Sub(b.at)
	if elapsed <= 0 {
		return b.tokens
	}
	return math.Min(float64(l.rule.Burst), b.tokens+float64(elapsed)/float64(l.rule.Every))
}

func (l *Limiter) sweep(now time.Time) {
	if now.Sub(l.lastSweep) < sweepInterval {
		return
	}
	l.lastSweep = now
	for key, b := range l.buckets {
		if l.refilled(b, now) >= float64(l.rule.Burst) {
			delete(l.buckets, key)
		}
	}
}
