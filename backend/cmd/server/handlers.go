package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	//"net/url"
	"os"
	//"strings"
	"time"
	//

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/Akawatmor/skoservice-authenserver/internal/auth"
	"github.com/Akawatmor/skoservice-authenserver/internal/db"
	"github.com/Akawatmor/skoservice-authenserver/internal/utils"
)

// Models

type RegisterRequest struct {
	Name           string `json:"name"`
	Email          string `json:"email"`
	Password       string `json:"password"`
	TurnstileToken string `json:"turnstileToken"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type UpdateUserReq struct {
	Name  string `json:"name"`
	Image string `json:"image"`
}

type UserResponse struct {
	ID            string    `json:"id"`
	Name          string    `json:"name"`
	Email         string    `json:"email"`
	EmailVerified time.Time `json:"email_verified"`
	Image         string    `json:"image"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// Handlers

// @Summary Register a new user
// @Description Register a new user with email, password, and turnstile token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body RegisterRequest true "Register Request"
// @Success 201 {object} UserResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /auth/register [post]
func registerHandler(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "Invalid request body")
	}

	// Verify Turnstile Captcha
	if err := utils.VerifyTurnstile(req.TurnstileToken, c.IP()); err != nil {
		return fiber.NewError(fiber.StatusForbidden, "Captcha verification failed: "+err.Error())
	}

	if !utils.ValidateEmail(req.Email) {
		return fiber.NewError(fiber.StatusBadRequest, "Invalid email format")
	}

	isValidPass, passMsg := utils.ValidatePassword(req.Password)
	if !isValidPass {
		return fiber.NewError(fiber.StatusBadRequest, passMsg)
	}

	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to hash password")
	}

	id, err := utils.GenerateID()
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to generate ID")
	}

	userID := pgtype.Text{String: id, Valid: true}
	userName := pgtype.Text{String: req.Name, Valid: true}
	userEmail := pgtype.Text{String: req.Email, Valid: true}
	emailVerified := pgtype.Timestamp{Valid: false}
	userImage := pgtype.Text{Valid: false}
	userPass := pgtype.Text{String: hashedPassword, Valid: true}

	user, err := queries.CreateUser(context.Background(), userID, userName, userEmail, emailVerified, userImage, userPass)
	if err != nil {
		return fiber.NewError(fiber.StatusConflict, "User likely already exists: "+err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(user)
}

// @Summary Login user
// @Description Login with email and password to get JWT token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body LoginRequest true "Login Request"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /auth/login [post]
func loginHandler(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "Invalid request body")
	}

	pgEmail := pgtype.Text{String: req.Email, Valid: true}
	user, err := queries.GetUserByEmail(context.Background(), pgEmail)
	if err != nil {
		return fiber.NewError(fiber.StatusUnauthorized, "Invalid credentials")
	}

	if !user.Password.Valid || !utils.CheckPasswordHash(req.Password, user.Password.String) {
		return fiber.NewError(fiber.StatusUnauthorized, "Invalid credentials")
	}

	token, payload, err := tokenMaker.CreateToken(user.ID, user.Email.String, []string{}, 24*time.Hour)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to create access token")
	}
	_ = payload

	return c.JSON(fiber.Map{
		"access_token": token,
		"user":         user,
	})
}

// @Summary Get User Profile
// @Description Get current user profile details
// @Tags User
// @Security BearerAuth
// @Produce json
// @Success 200 {object} UserResponse
// @Failure 404 {object} map[string]interface{}
// @Router /users/me [get]
func getUserMeHandler(c *fiber.Ctx) error {
	payload := c.Locals("payload").(*auth.Payload)
	pgID := pgtype.Text{String: payload.UserID, Valid: true}
	user, err := queries.GetUserByID(context.Background(), pgID)
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "User not found")
	}
	return c.JSON(user)
}

// @Summary Update User Profile
// @Description Update user name or image
// @Tags User
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UpdateUserReq true "Update User Request"
// @Success 200 {object} UserResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /users/me [put]
func updateUserMeHandler(c *fiber.Ctx) error {
	payload := c.Locals("payload").(*auth.Payload)
	var req UpdateUserReq
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "Invalid body")
	}

	pgID := pgtype.Text{String: payload.UserID, Valid: true}
	pgName := pgtype.Text{String: req.Name, Valid: req.Name != ""}
	pgEmail := pgtype.Text{Valid: false}
	pgVerified := pgtype.Timestamp{Valid: false}
	pgImage := pgtype.Text{String: req.Image, Valid: req.Image != ""}

	user, err := queries.UpdateUser(context.Background(), pgID, pgName, pgEmail, pgVerified, pgImage)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to update user")
	}
	return c.JSON(user)
}

// @Summary Get Google OAuth URL
// @Description Get the URL to redirect the user for Google OAuth
// @Tags Auth
// @Produce json
// @Success 200 {object} map[string]string
// @Router /auth/oauth/google/url [get]
func googleUrlHandler(c *fiber.Ctx) error {
	clientID := os.Getenv("OAUTH_GOOGLE_CLIENT_ID")
	redirectURI := os.Getenv("OAUTH_GOOGLE_REDIRECT_URL")
	if redirectURI == "" {
		redirectURI = "http://localhost:3000/auth/callback/google"
	}
	// Scope: email profile
	scope := "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
	authURL := fmt.Sprintf("https://accounts.google.com/o/oauth2/v2/auth?client_id=%s&redirect_uri=%s&response_type=code&scope=%s&access_type=offline&prompt=consent", clientID, redirectURI, scope)
	return c.JSON(fiber.Map{"url": authURL})
}

// @Summary Google OAuth Callback
// @Description Exchange auth code for token
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body map[string]string true "Code"
// @Success 200 {object} map[string]interface{}
// @Router /auth/oauth/google/callback [post]
func googleCallbackHandler(c *fiber.Ctx) error {
	type CallbackReq struct {
		Code string `json:"code"`
	}
	var req CallbackReq
	if err := c.BodyParser(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "Invalid request body")
	}

	clientID := os.Getenv("OAUTH_GOOGLE_CLIENT_ID")
	clientSecret := os.Getenv("OAUTH_GOOGLE_CLIENT_SECRET")
	redirectURI := os.Getenv("OAUTH_GOOGLE_REDIRECT_URL")
	if redirectURI == "" {
		redirectURI = "http://localhost:3000/auth/callback/google"
	}

	// Exchange Code for Token
	reqBodyData := map[string]string{
		"client_id":     clientID,
		"client_secret": clientSecret,
		"code":          req.Code,
		"grant_type":    "authorization_code",
		"redirect_uri":  redirectURI,
	}
	jsonBody, _ := json.Marshal(reqBodyData)

	tokenReq, _ := http.NewRequest("POST", "https://oauth2.googleapis.com/token", bytes.NewBuffer(jsonBody))
	tokenReq.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(tokenReq)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to exchange code: "+err.Error())
	}
	defer resp.Body.Close()

	type GoogleTokenResp struct {
		AccessToken string `json:"access_token"`
		IdToken     string `json:"id_token"`
		Error       string `json:"error"`
	}
	var tokenData GoogleTokenResp
	if err := json.NewDecoder(resp.Body).Decode(&tokenData); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to parse token response")
	}

	if tokenData.Error != "" {
		return fiber.NewError(fiber.StatusUnauthorized, "Google Error: "+tokenData.Error)
	}

	// Get User Info
	userReq, _ := http.NewRequest("GET", "https://www.googleapis.com/oauth2/v2/userinfo", nil)
	userReq.Header.Set("Authorization", "Bearer "+tokenData.AccessToken)

	userResp, err := client.Do(userReq)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to fetch user profile: "+err.Error())
	}
	defer userResp.Body.Close()

	type GoogleUser struct {
		ID            string `json:"id"`
		Email         string `json:"email"`
		VerifiedEmail bool   `json:"verified_email"`
		Name          string `json:"name"`
		Picture       string `json:"picture"`
	}
	var gUser GoogleUser
	if err := json.NewDecoder(userResp.Body).Decode(&gUser); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to parse user profile")
	}

	// DB Logic
	pgEmail := pgtype.Text{String: gUser.Email, Valid: true}
	user, err := queries.GetUserByEmail(context.Background(), pgEmail)

	if err != nil {
		// Register
		id, _ := utils.GenerateID()
		userID := pgtype.Text{String: id, Valid: true}
		userName := pgtype.Text{String: gUser.Name, Valid: true}
		userEmail := pgtype.Text{String: gUser.Email, Valid: true}
		emailVerified := pgtype.Timestamp{Time: time.Now(), Valid: true} // Trust Google
		userImage := pgtype.Text{String: gUser.Picture, Valid: gUser.Picture != ""}
		userPass := pgtype.Text{Valid: false}

		newUser, err := queries.CreateUser(context.Background(), userID, userName, userEmail, emailVerified, userImage, userPass)
		if err != nil {
			return fiber.NewError(fiber.StatusInternalServerError, "Failed to create oauth user: "+err.Error())
		}
		user = db.GetUserByEmailRow{
			ID:            newUser.ID,
			Name:          newUser.Name,
			Email:         newUser.Email,
			EmailVerified: newUser.EmailVerified,
			Image:         newUser.Image,
			Password:      newUser.Password,
			CreatedAt:     newUser.CreatedAt,
			UpdatedAt:     newUser.UpdatedAt,
		}
	}

	// Create Token
	token, _, err := tokenMaker.CreateToken(user.ID, user.Email.String, []string{}, 24*time.Hour)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "Failed to create app token")
	}

	return c.JSON(fiber.Map{
		"access_token": token,
		"user":         user,
	})
}
