package email_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/tsantanadev/cesta/backend/internal/platform/email"
)

func TestResendPostsTheMessageWithTheAPIKey(t *testing.T) {
	var got map[string]any
	var auth string
	api := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/emails" {
			t.Errorf("request = %s %s, want POST /emails", r.Method, r.URL.Path)
		}
		auth = r.Header.Get("Authorization")
		if err := json.NewDecoder(r.Body).Decode(&got); err != nil {
			t.Errorf("decode body: %v", err)
		}
		_, _ = w.Write([]byte(`{"id": "abc"}`))
	}))
	defer api.Close()
	r := email.NewResend("re_key", "Cesta <convites@cesta.tsantana.dev>", email.WithResendURL(api.URL))

	err := r.Send(context.Background(), email.Message{To: "carla@example.com", Subject: "Hi", Text: "text", HTML: "<p>html</p>"})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
	if auth != "Bearer re_key" {
		t.Fatalf("Authorization = %q, want Bearer re_key", auth)
	}
	to, _ := got["to"].([]any)
	if got["from"] != "Cesta <convites@cesta.tsantana.dev>" || len(to) != 1 || to[0] != "carla@example.com" ||
		got["subject"] != "Hi" || got["text"] != "text" || got["html"] != "<p>html</p>" {
		t.Fatalf("body = %v, want the message from Cesta to Carla", got)
	}
}

func TestResendReportsARejectedMessage(t *testing.T) {
	api := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnprocessableEntity)
		_, _ = w.Write([]byte(`{"message": "invalid to"}`))
	}))
	defer api.Close()
	r := email.NewResend("re_key", "Cesta <convites@cesta.tsantana.dev>", email.WithResendURL(api.URL))

	if err := r.Send(context.Background(), email.Message{To: "x"}); err == nil {
		t.Fatal("Send succeeded, want an error for status 422")
	}
}
