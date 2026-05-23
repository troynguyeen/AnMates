package handlers

import (
	"context"
	"strings"
	"time"

	"github.com/anmates/api/middleware"
	"github.com/anmates/api/models"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	pool *pgxpool.Pool
}

func NewUser(pool *pgxpool.Pool) *User { return &User{pool: pool} }

func (u *User) GetProfile(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var out userOut
	err := u.pool.QueryRow(ctx, `
		SELECT id::text, name, email, avatar_url, bio FROM users WHERE id = $1
	`, uid).Scan(&out.ID, &out.Name, &out.Email, &out.AvatarURL, &out.Bio)
	if err != nil {
		return models.Err(c, fiber.StatusNotFound, models.ErrNotFound, "user not found")
	}
	return models.OK(c, out)
}

type updateProfileReq struct {
	Name      *string `json:"name"`
	AvatarURL *string `json:"avatar_url"`
	Bio       *string `json:"bio"`
}

func (u *User) UpdateProfile(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r updateProfileReq
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}
	if r.Name != nil {
		trim := strings.TrimSpace(*r.Name)
		if trim == "" {
			return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "name must not be empty")
		}
		r.Name = &trim
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var out userOut
	err := u.pool.QueryRow(ctx, `
		UPDATE users SET
			name       = COALESCE($2, name),
			avatar_url = COALESCE($3, avatar_url),
			bio        = COALESCE($4, bio)
		WHERE id = $1
		RETURNING id::text, name, email, avatar_url, bio
	`, uid, r.Name, r.AvatarURL, r.Bio).Scan(
		&out.ID, &out.Name, &out.Email, &out.AvatarURL, &out.Bio)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "update failed")
	}
	return models.OK(c, out)
}
