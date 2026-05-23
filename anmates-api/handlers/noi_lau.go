package handlers

import (
	"context"
	"errors"
	"time"

	"github.com/anmates/api/middleware"
	"github.com/anmates/api/models"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type NoiLau struct {
	pool *pgxpool.Pool
}

func NewNoiLau(pool *pgxpool.Pool) *NoiLau { return &NoiLau{pool: pool} }

func (n *NoiLau) Get(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	matchID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid match id")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var member bool
	_ = n.pool.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM matches
			WHERE id = $1 AND (user_a_id = $2 OR user_b_id = $2))
	`, matchID, uid).Scan(&member)
	if !member {
		return models.Err(c, fiber.StatusNotFound, models.ErrMatchNotFound, "match not found")
	}

	var p models.NoiLauProgress
	p.MatchID = matchID
	err = n.pool.QueryRow(ctx, `
		SELECT points, level, last_activity FROM noi_lau_progress WHERE match_id = $1
	`, matchID).Scan(&p.Points, &p.Level, &p.LastActivity)
	if errors.Is(err, pgx.ErrNoRows) {
		// Match exists but progress row missing — return zero state.
		p.Points = 0
		p.Level = 1
	} else if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "query failed")
	}
	p.NextThreshold = models.NextThreshold(p.Points)
	p.Locked = p.Level >= 3
	return models.OK(c, p)
}
