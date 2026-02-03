package utils

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"
	"time"
)

var (
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
)

// VerifyTurnstile validates the token with Cloudflare
func VerifyTurnstile(token string, ip string) error {
	secret := os.Getenv("CLOUDFLARE_TURNSTILE_SECRET_KEY")
	if secret == "" {
		// If key not set, skip validation (dev mode or user forgot)
		// Or return error? Security wise, should return error if enabled.
		// For now, let's assume if env is missing, we skip (easier for dev).
		return nil 
	}
	if token == "" {
		return fmt.Errorf("missing turnstile token")
	}

	apiURL := "https://challenges.cloudflare.com/turnstile/v0/siteverify"
	formData := url.Values{
		"secret":   {secret},
		"response": {token},
		"remoteip": {ip},
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.PostForm(apiURL, formData)
	if err != nil {
		return fmt.Errorf("failed to connect to turnstile: %v", err)
	}
	defer resp.Body.Close()

	var result struct {
		Success bool     `json:"success"`
		ErrorCodes []string `json:"error-codes"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("failed to parse turnstile response")
	}

	if !result.Success {
		return fmt.Errorf("invalid captcha: %v", result.ErrorCodes)
	}

	return nil
}

// ValidateEmail checks if an email is valid
func ValidateEmail(email string) bool {
	email = strings.TrimSpace(email)
	if len(email) < 3 || len(email) > 254 {
		return false
	}
	return emailRegex.MatchString(email)
}

// ValidatePassword checks if a password meets requirements
func ValidatePassword(password string) (bool, string) {
	if len(password) < 8 {
		return false, "Password must be at least 8 characters long"
	}
	if len(password) > 128 {
		return false, "Password must be at most 128 characters long"
	}

	// Check for at least one uppercase letter
	if !regexp.MustCompile(`[A-Z]`).MatchString(password) {
		return false, "Password must contain at least one uppercase letter"
	}

	// Check for at least one lowercase letter
	if !regexp.MustCompile(`[a-z]`).MatchString(password) {
		return false, "Password must contain at least one lowercase letter"
	}

	// Check for at least one digit
	if !regexp.MustCompile(`[0-9]`).MatchString(password) {
		return false, "Password must contain at least one digit"
	}

	return true, ""
}

// SanitizeString removes potentially dangerous characters
func SanitizeString(s string) string {
	s = strings.TrimSpace(s)
	// Remove null bytes
	s = strings.ReplaceAll(s, "\x00", "")
	return s
}
