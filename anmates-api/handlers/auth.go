package handlers

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"net/mail"
	"strings"
	"time"

	"github.com/anmates/api/config"
	"github.com/anmates/api/middleware"
	"github.com/anmates/api/models"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type Auth struct {
	pool *pgxpool.Pool
	cfg  *config.Config
}

func NewAuth(pool *pgxpool.Pool, cfg *config.Config) *Auth {
	return &Auth{pool: pool, cfg: cfg}
}

type registerReq struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type refreshReq struct {
	RefreshToken string `json:"refresh_token"`
}

type tokenResp struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token,omitempty"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         *userOut  `json:"user,omitempty"`
}

type userOut struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Email     string  `json:"email"`
	AvatarURL *string `json:"avatar_url"`
	Bio       *string `json:"bio"`
}

func (a *Auth) Register(c *fiber.Ctx) error {
	var r registerReq
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}
	r.Email = strings.ToLower(strings.TrimSpace(r.Email))
	r.Name = strings.TrimSpace(r.Name)
	if !validEmail(r.Email) || len(r.Password) < 10 || r.Name == "" {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
			"name required; valid email; password >= 10 chars")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(r.Password), bcrypt.DefaultCost)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "hash failed")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var u models.User
	err = a.pool.QueryRow(ctx, `
		INSERT INTO users (email, password_hash, name)
		VALUES ($1, $2, $3)
		RETURNING id, email, name, avatar_url, bio, created_at
	`, r.Email, string(hash), r.Name).Scan(
		&u.ID, &u.Email, &u.Name, &u.AvatarURL, &u.Bio, &u.CreatedAt)
	if err != nil {
		if isUniqueViolation(err) {
			return models.Err(c, fiber.StatusConflict, models.ErrConflict, "email already registered")
		}
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "create user failed")
	}

	return a.issueTokens(c, ctx, &u, fiber.StatusCreated)
}

func (a *Auth) Login(c *fiber.Ctx) error {
	var r loginReq
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}
	r.Email = strings.ToLower(strings.TrimSpace(r.Email))

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var u models.User
	err := a.pool.QueryRow(ctx, `
		SELECT id, email, password_hash, name, avatar_url, bio, created_at
		FROM users WHERE email = $1
	`, r.Email).Scan(&u.ID, &u.Email, &u.PasswordHash, &u.Name, &u.AvatarURL, &u.Bio, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) ||
		(err == nil && bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(r.Password)) != nil) {
		return models.Err(c, fiber.StatusUnauthorized, models.ErrUnauthorized, "invalid credentials")
	}
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "login failed")
	}
	return a.issueTokens(c, ctx, &u, fiber.StatusOK)
}

func (a *Auth) Refresh(c *fiber.Ctx) error {
	var r refreshReq
	if err := c.BodyParser(&r); err != nil || r.RefreshToken == "" {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "refresh_token required")
	}
	h := hashToken(r.RefreshToken)

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var u models.User
	err := a.pool.QueryRow(ctx, `
		SELECT u.id, u.email, u.name, u.avatar_url, u.bio, u.created_at
		FROM refresh_tokens rt
		JOIN users u ON u.id = rt.user_id
		WHERE rt.token_hash = $1 AND rt.expires_at > now()
	`, h).Scan(&u.ID, &u.Email, &u.Name, &u.AvatarURL, &u.Bio, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.Err(c, fiber.StatusUnauthorized, models.ErrUnauthorized, "invalid refresh token")
	}
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "refresh failed")
	}

	// Rotate: delete the used token before issuing a fresh pair.
	if _, err := a.pool.Exec(ctx, `DELETE FROM refresh_tokens WHERE token_hash = $1`, h); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "rotate failed")
	}
	return a.issueTokens(c, ctx, &u, fiber.StatusOK)
}

func (a *Auth) Logout(c *fiber.Ctx) error {
	var r refreshReq
	if err := c.BodyParser(&r); err == nil && r.RefreshToken != "" {
		ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
		defer cancel()
		_, _ = a.pool.Exec(ctx, `DELETE FROM refresh_tokens WHERE token_hash = $1`, hashToken(r.RefreshToken))
	}
	return models.OK(c, fiber.Map{"logged_out": true})
}

func (a *Auth) issueTokens(c *fiber.Ctx, ctx context.Context, u *models.User, status int) error {
	access, exp, err := middleware.SignAccessToken(a.cfg.JWTSecret, u.ID, a.cfg.JWTAccessExpire)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "token sign failed")
	}
	raw, err := randomToken()
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "token gen failed")
	}
	if _, err := a.pool.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, u.ID, hashToken(raw), time.Now().Add(a.cfg.JWTRefreshExpire)); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "store refresh failed")
	}

	return c.Status(status).JSON(models.SuccessEnvelope{
		Success: true,
		Data: tokenResp{
			AccessToken:  access,
			RefreshToken: raw,
			ExpiresAt:    exp,
			User: &userOut{
				ID: u.ID.String(), Name: u.Name, Email: u.Email,
				AvatarURL: u.AvatarURL, Bio: u.Bio,
			},
		},
	})
}

func randomToken() (string, error) {
	b := make([]byte, 48)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b), nil
}

func hashToken(raw string) string {
	sum := sha256.Sum256([]byte(raw))
	return base64.StdEncoding.EncodeToString(sum[:])
}

func validEmail(s string) bool {
	if s == "" {
		return false
	}
	_, err := mail.ParseAddress(s)
	return err == nil
}

func isUniqueViolation(err error) bool {
	return err != nil && strings.Contains(err.Error(), "23505")
}
