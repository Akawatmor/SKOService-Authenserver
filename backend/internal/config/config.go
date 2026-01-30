package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration
type Config struct {
	// Server
	Port        string
	Environment string

	// Database
	DatabaseURL string
	DBHost      string
	DBPort      int
	DBUser      string
	DBPassword  string
	DBName      string
	DBSchema    string
	DBMaxConns  int
	DBMinConns  int

	// Redis
	RedisURL      string
	RedisPassword string
	RedisDB       int

	// Authentication
	PasetoSecretKey      string
	SessionDuration      time.Duration
	RefreshTokenDuration time.Duration

	// OAuth
	OAuthGoogleClientID     string
	OAuthGoogleClientSecret string
	OAuthGoogleRedirectURL  string

	OAuthGitHubClientID     string
	OAuthGitHubClientSecret string
	OAuthGitHubRedirectURL  string

	// CORS
	CORSOrigins string

	// Rate Limiting
	RateLimitMax      int
	RateLimitDuration time.Duration
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	cfg := &Config{
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("ENVIRONMENT", "development"),

		// Database
		DatabaseURL: getEnv("DATABASE_URL", ""),
		DBHost:      getEnv("DB_HOST", "localhost"),
		DBPort:      getEnvAsInt("DB_PORT", 5432),
		DBUser:      getEnv("DB_USER", "postgres"),
		DBPassword:  getEnv("DB_PASSWORD", "postgres"),
		DBName:      getEnv("DB_NAME", "skoservice"),
		DBSchema:    getEnv("DB_SCHEMA", "authenserver_service"),
		DBMaxConns:  getEnvAsInt("DB_MAX_CONNECTIONS", 100),
		DBMinConns:  getEnvAsInt("DB_MIN_CONNECTIONS", 10),

		// Redis
		RedisURL:      getEnv("REDIS_URL", "redis://localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvAsInt("REDIS_DB", 0),

		// Authentication
		PasetoSecretKey:      getEnv("PASETO_SECRET_KEY", ""),
		SessionDuration:      getEnvAsDuration("SESSION_DURATION", 24*time.Hour),
		RefreshTokenDuration: getEnvAsDuration("REFRESH_TOKEN_DURATION", 168*time.Hour),

		// OAuth
		OAuthGoogleClientID:     getEnv("OAUTH_GOOGLE_CLIENT_ID", ""),
		OAuthGoogleClientSecret: getEnv("OAUTH_GOOGLE_CLIENT_SECRET", ""),
		OAuthGoogleRedirectURL:  getEnv("OAUTH_GOOGLE_REDIRECT_URL", ""),

		OAuthGitHubClientID:     getEnv("OAUTH_GITHUB_CLIENT_ID", ""),
		OAuthGitHubClientSecret: getEnv("OAUTH_GITHUB_CLIENT_SECRET", ""),
		OAuthGitHubRedirectURL:  getEnv("OAUTH_GITHUB_REDIRECT_URL", ""),

		// CORS
		CORSOrigins: getEnv("CORS_ORIGINS", "http://localhost:3000"),

		// Rate Limiting
		RateLimitMax:      getEnvAsInt("RATE_LIMIT_MAX", 100),
		RateLimitDuration: getEnvAsDuration("RATE_LIMIT_DURATION", time.Minute),
	}

	// Validate required fields
	if cfg.PasetoSecretKey == "" {
		return nil, fmt.Errorf("PASETO_SECRET_KEY is required")
	}
	if len(cfg.PasetoSecretKey) < 32 {
		return nil, fmt.Errorf("PASETO_SECRET_KEY must be at least 32 bytes")
	}

	return cfg, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}
