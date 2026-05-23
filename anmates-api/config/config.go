package config

import (
	"fmt"
	"os"
	"time"
)

type Config struct {
	DatabaseURL       string
	JWTSecret         []byte
	JWTAccessExpire   time.Duration
	JWTRefreshExpire  time.Duration
	Port              string
	Env               string
}

func Load() (*Config, error) {
	c := &Config{
		DatabaseURL: os.Getenv("DATABASE_URL"),
		JWTSecret:   []byte(os.Getenv("JWT_SECRET")),
		Port:        getOr("PORT", "8080"),
		Env:         getOr("ENV", "production"),
	}
	if c.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	if len(c.JWTSecret) < 32 {
		return nil, fmt.Errorf("JWT_SECRET must be at least 32 bytes (got %d)", len(c.JWTSecret))
	}

	access, err := time.ParseDuration(getOr("JWT_ACCESS_EXPIRE", "15m"))
	if err != nil {
		return nil, fmt.Errorf("JWT_ACCESS_EXPIRE: %w", err)
	}
	c.JWTAccessExpire = access

	refresh, err := time.ParseDuration(getOr("JWT_REFRESH_EXPIRE", "168h"))
	if err != nil {
		return nil, fmt.Errorf("JWT_REFRESH_EXPIRE: %w", err)
	}
	c.JWTRefreshExpire = refresh

	return c, nil
}

func getOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
