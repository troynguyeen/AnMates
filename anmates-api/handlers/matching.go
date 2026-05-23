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

type Matching struct {
	pool *pgxpool.Pool
}

func NewMatching(pool *pgxpool.Pool) *Matching { return &Matching{pool: pool} }

// List returns candidate users with ≥2 overlapping food_names, excluding those
// already matched/blocked or the caller themself. Score is Jaccard similarity:
// |A∩B| / |A∪B| computed entirely in SQL.
func (m *Matching) List(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	const q = `
		WITH my_foods AS (
			SELECT DISTINCT food_name FROM wishlists WHERE user_id = $1
		),
		my_count AS (SELECT COUNT(*)::int AS c FROM my_foods),
		theirs AS (
			SELECT
				w.user_id,
				COUNT(*) FILTER (WHERE w.food_name IN (SELECT food_name FROM my_foods))::int AS overlap,
				COUNT(*)::int AS their_count,
				array_agg(DISTINCT w.food_name)
					FILTER (WHERE w.food_name IN (SELECT food_name FROM my_foods)) AS overlap_foods
			FROM wishlists w
			WHERE w.user_id <> $1
			  AND NOT EXISTS (
				SELECT 1 FROM matches m
				WHERE (m.user_a_id = $1 AND m.user_b_id = w.user_id)
				   OR (m.user_a_id = w.user_id AND m.user_b_id = $1)
			  )
			GROUP BY w.user_id
		)
		SELECT u.id, u.name, u.avatar_url,
		       t.overlap, t.overlap_foods,
		       (t.overlap::float / NULLIF(mc.c + t.their_count - t.overlap, 0)) AS score
		FROM theirs t
		JOIN users u ON u.id = t.user_id
		CROSS JOIN my_count mc
		WHERE t.overlap >= 2
		ORDER BY score DESC, t.overlap DESC
		LIMIT 50
	`
	rows, err := m.pool.Query(ctx, q, uid)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "query failed")
	}
	defer rows.Close()

	out := make([]models.MatchCandidate, 0, 16)
	for rows.Next() {
		var mc models.MatchCandidate
		if err := rows.Scan(&mc.UserID, &mc.Name, &mc.AvatarURL,
			&mc.OverlapCount, &mc.OverlapFoods, &mc.Score); err != nil {
			return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "scan failed")
		}
		out = append(out, mc)
	}
	return models.OK(c, out)
}

// Accept creates a match row between the caller and the target user. Idempotent:
// if a match already exists (in either direction), returns the existing one.
// :id here is the *other user's* id, not a match id.
func (m *Matching) Accept(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	other, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid user id")
	}
	if other == uid {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "cannot match self")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	// Existing?
	var match models.Match
	err = m.pool.QueryRow(ctx, `
		SELECT id, user_a_id, user_b_id, status, score, created_at FROM matches
		WHERE (user_a_id = $1 AND user_b_id = $2) OR (user_a_id = $2 AND user_b_id = $1)
	`, uid, other).Scan(&match.ID, &match.UserAID, &match.UserBID, &match.Status, &match.Score, &match.CreatedAt)
	if err == nil {
		return models.OK(c, match)
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "check match failed")
	}

	// Compute score on-the-fly so the match remembers the strength of overlap.
	var score float64
	err = m.pool.QueryRow(ctx, `
		WITH a AS (SELECT DISTINCT food_name FROM wishlists WHERE user_id = $1),
		     b AS (SELECT DISTINCT food_name FROM wishlists WHERE user_id = $2),
		     inter AS (SELECT COUNT(*)::float c FROM a JOIN b USING (food_name)),
		     uni   AS (SELECT COUNT(*)::float c FROM (SELECT food_name FROM a UNION SELECT food_name FROM b) u)
		SELECT CASE WHEN uni.c = 0 THEN 0 ELSE inter.c / uni.c END FROM inter, uni
	`, uid, other).Scan(&score)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "score failed")
	}

	tx, err := m.pool.Begin(ctx)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "begin failed")
	}
	defer func() { _ = tx.Rollback(ctx) }()

	err = tx.QueryRow(ctx, `
		INSERT INTO matches (user_a_id, user_b_id, status, score)
		VALUES ($1, $2, 'accepted', $3)
		RETURNING id, user_a_id, user_b_id, status, score, created_at
	`, uid, other, score).Scan(
		&match.ID, &match.UserAID, &match.UserBID, &match.Status, &match.Score, &match.CreatedAt)
	if err != nil {
		if isUniqueViolation(err) {
			// Someone else inserted between our check and insert; re-fetch.
			_ = tx.Rollback(ctx)
			err = m.pool.QueryRow(ctx, `
				SELECT id, user_a_id, user_b_id, status, score, created_at FROM matches
				WHERE (user_a_id = $1 AND user_b_id = $2) OR (user_a_id = $2 AND user_b_id = $1)
			`, uid, other).Scan(&match.ID, &match.UserAID, &match.UserBID, &match.Status, &match.Score, &match.CreatedAt)
			if err != nil {
				return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "refetch failed")
			}
			return models.OK(c, match)
		}
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "insert match failed")
	}

	// Seed the Nồi Lẩu row for this match.
	if _, err := tx.Exec(ctx,
		`INSERT INTO noi_lau_progress (match_id, points, level) VALUES ($1, 0, 1)`,
		match.ID,
	); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "seed progress failed")
	}
	if err := tx.Commit(ctx); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "commit failed")
	}
	return c.Status(fiber.StatusCreated).JSON(models.SuccessEnvelope{Success: true, Data: match})
}
