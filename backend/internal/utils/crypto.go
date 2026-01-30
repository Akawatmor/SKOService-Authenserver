package utils
package utils

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"




































}	return base64.URLEncoding.EncodeToString(bytes), nil	}		return "", fmt.Errorf("failed to generate ID: %w", err)	if _, err := rand.Read(bytes); err != nil {	bytes := make([]byte, 16)func GenerateID() (string, error) {// GenerateID generates a random ID (similar to cuid)}	return base64.URLEncoding.EncodeToString(bytes)[:length], nil	}		return "", fmt.Errorf("failed to generate random string: %w", err)	if _, err := rand.Read(bytes); err != nil {	bytes := make([]byte, length)func GenerateRandomString(length int) (string, error) {// GenerateRandomString generates a random string of specified length}	return err == nil	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))func CheckPasswordHash(password, hash string) bool {// CheckPasswordHash compares a password with its hash}	return string(bytes), nil	}		return "", fmt.Errorf("failed to hash password: %w", err)	if err != nil {	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)func HashPassword(password string) (string, error) {// HashPassword hashes a password using bcrypt)	"golang.org/x/crypto/bcrypt"