// Package names checks the names people type: display names and List names.
package names

import (
	"strings"
	"unicode"
	"unicode/utf8"
)

// Normalize trims name and reports whether it is acceptable: 1 to maxRunes
// characters of valid UTF-8 with no control characters.
func Normalize(name string, maxRunes int) (string, bool) {
	name = strings.TrimSpace(name)
	if name == "" || utf8.RuneCountInString(name) > maxRunes || !utf8.ValidString(name) {
		return "", false
	}
	for _, r := range name {
		if unicode.IsControl(r) {
			return "", false
		}
	}
	return name, true
}
