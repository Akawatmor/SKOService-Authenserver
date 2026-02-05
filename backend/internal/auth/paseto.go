package auth

import (
	"fmt"
	"time"

	"github.com/o1egl/paseto"
)

type TokenMaker struct {
	paseto       *paseto.V2
	symmetricKey []byte
}

func NewTokenMaker(symmetricKey string) (*TokenMaker, error) {
	if len(symmetricKey) != 32 {
		return nil, fmt.Errorf("invalid key size: must be exactly 32 characters")
	}

	maker := &TokenMaker{
		paseto:       paseto.NewV2(),
		symmetricKey: []byte(symmetricKey),
	}

	return maker, nil
}

type Payload struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Email     string    `json:"email"`
	Roles     []string  `json:"roles"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiredAt time.Time `json:"expired_at"`
}

func (payload *Payload) Valid() error {
	if time.Now().After(payload.ExpiredAt) {
		return fmt.Errorf("token has expired")
	}
	return nil
}

func (maker *TokenMaker) CreateToken(userID string, email string, roles []string, duration time.Duration) (string, *Payload, error) {
	payload := &Payload{
		ID:        fmt.Sprintf("%d", time.Now().UnixNano()), // Simple ID
		UserID:    userID,
		Email:     email,
		Roles:     roles,
		IssuedAt:  time.Now(),
		ExpiredAt: time.Now().Add(duration),
	}

	token, err := maker.paseto.Encrypt(maker.symmetricKey, payload, nil)
	return token, payload, err
}

func (maker *TokenMaker) VerifyToken(token string) (*Payload, error) {
	payload := &Payload{}

	err := maker.paseto.Decrypt(token, maker.symmetricKey, payload, nil)
	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	err = payload.Valid()
	if err != nil {
		return nil, err
	}

	return payload, nil
}
