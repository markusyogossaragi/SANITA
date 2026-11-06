package utils

import (
	"html"
	"regexp"
	"strings"
)

var (
	rxLocation = regexp.MustCompile(`^[a-zA-Z0-9\s.,\-_()/]{2,100}$`)
	rxUsername = regexp.MustCompile(`^[a-zA-Z0-9_\-.]{3,30}$`)
)

// SanitizeString strips HTML tags and escapes malicious characters
func SanitizeString(input string) string {
	trimmed := strings.TrimSpace(input)
	// Remove dangerous script/tag characters
	tagStrip := regexp.MustCompile(`<[^>]*>`)
	cleaned := tagStrip.ReplaceAllString(trimmed, "")
	return html.EscapeString(cleaned)
}

// ValidateLocation verifies location string syntax
func ValidateLocation(loc string) bool {
	return rxLocation.MatchString(strings.TrimSpace(loc))
}

// ValidateUsername checks username syntax
func ValidateUsername(username string) bool {
	return rxUsername.MatchString(strings.TrimSpace(username))
}