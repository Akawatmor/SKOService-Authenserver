package utils
package utils

import (
	"regexp"
	"strings"
)

var (
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
)













































}	return s	s = strings.ReplaceAll(s, "\x00", "")	// Remove null bytes	s = strings.TrimSpace(s)func SanitizeString(s string) string {// SanitizeString removes potentially dangerous characters}	return true, ""	}		return false, "Password must contain at least one digit"	if !regexp.MustCompile(`[0-9]`).MatchString(password) {	// Check for at least one digit	}		return false, "Password must contain at least one lowercase letter"	if !regexp.MustCompile(`[a-z]`).MatchString(password) {	// Check for at least one lowercase letter	}		return false, "Password must contain at least one uppercase letter"	if !regexp.MustCompile(`[A-Z]`).MatchString(password) {	// Check for at least one uppercase letter	}		return false, "Password must be at most 128 characters long"	if len(password) > 128 {	}		return false, "Password must be at least 8 characters long"	if len(password) < 8 {func ValidatePassword(password string) (bool, string) {// ValidatePassword checks if a password meets requirements}	return emailRegex.MatchString(email)	}		return false	if len(email) < 3 || len(email) > 254 {	email = strings.TrimSpace(email)func ValidateEmail(email string) bool {// ValidateEmail checks if an email is valid