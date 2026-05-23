package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/anmates/api/middleware"
	"github.com/anmates/api/models"
	wsx "github.com/anmates/api/ws"
	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Chat struct {
	pool *pgxpool.Pool
	hub  *wsx.Hub
}

func NewChat(pool *pgxpool.Pool, hub *wsx.Hub) *Chat {
	return &Chat{pool: pool, hub: hub}
}

// History returns paginated messages oldest→newest using cursor=created_at.
func (ch *Chat) History(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	matchID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid match id")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	if !ch.userInMatch(ctx, matchID, uid) {
		return models.Err(c, fiber.StatusNotFound, models.ErrMatchNotFound, "match not found")
	}

	limit := c.QueryInt("limit", 50)
	if limit < 1 || limit > 200 {
		limit = 50
	}
	cursor := c.Query("cursor")

	var rows pgx.Rows
	if cursor == "" {
		rows, err = ch.pool.Query(ctx, `
			SELECT id, match_id, sender_id, content, msg_type, created_at
			FROM messages WHERE match_id = $1
			ORDER BY created_at DESC LIMIT $2
		`, matchID, limit)
	} else {
		t, perr := time.Parse(time.RFC3339Nano, cursor)
		if perr != nil {
			return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid cursor")
		}
		rows, err = ch.pool.Query(ctx, `
			SELECT id, match_id, sender_id, content, msg_type, created_at
			FROM messages WHERE match_id = $1 AND created_at < $2
			ORDER BY created_at DESC LIMIT $3
		`, matchID, t, limit)
	}
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "query failed")
	}
	defer rows.Close()

	out := make([]models.Message, 0, limit)
	for rows.Next() {
		var m models.Message
		if err := rows.Scan(&m.ID, &m.MatchID, &m.SenderID, &m.Content, &m.MsgType, &m.CreatedAt); err != nil {
			return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal, "scan failed")
		}
		out = append(out, m)
	}
	return models.OK(c, out)
}

// WebSocket is the Fiber handler installed at /ws/chat/:matchId. JWT auth was
// already validated upstream (we put the user id in Locals before upgrading).
func (ch *Chat) WebSocket() fiber.Handler {
	return websocket.New(func(conn *websocket.Conn) {
		matchID, ok := conn.Locals("match_id").(uuid.UUID)
		uid, okU := conn.Locals("user_id").(uuid.UUID)
		if !ok || !okU {
			_ = conn.Close()
			return
		}
		client := wsx.NewClient(conn, ch.hub, matchID, uid, ch.onIncoming)
		client.Run()
	})
}

type incomingMessage struct {
	Content string `json:"content"`
	MsgType string `json:"msg_type"`
}

// onIncoming processes one inbound envelope and returns what to broadcast.
// Persists messages, updates Nồi Lẩu, enforces the level-3 paywall.
func (ch *Chat) onIncoming(matchID, senderID uuid.UUID, env wsx.Envelope) (wsx.Envelope, error) {
	switch env.Type {
	case "typing":
		out, _ := json.Marshal(map[string]string{"user_id": senderID.String()})
		return wsx.Envelope{Type: "typing", Payload: out}, nil

	case "read":
		// Echo read receipts to peers without persisting (MVP scope).
		return wsx.Envelope{Type: "read", Payload: env.Payload}, nil

	case "message":
		var in incomingMessage
		if err := json.Unmarshal(env.Payload, &in); err != nil {
			return wsx.Envelope{}, errors.New("invalid payload")
		}
		in.Content = strings.TrimSpace(in.Content)
		if in.Content == "" || len(in.Content) > 2000 {
			return wsx.Envelope{}, errors.New("content empty or too long")
		}
		if in.MsgType == "" {
			in.MsgType = "text"
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Paywall: refuse new messages once Nồi Lẩu has hit level 3.
		var lvl int
		err := ch.pool.QueryRow(ctx,
			`SELECT level FROM noi_lau_progress WHERE match_id = $1`, matchID,
		).Scan(&lvl)
		if err == nil && lvl >= 3 {
			return wsx.Envelope{}, errors.New("chat locked at level 3 — upgrade to continue")
		}

		var saved models.Message
		err = ch.pool.QueryRow(ctx, `
			INSERT INTO messages (match_id, sender_id, content, msg_type)
			VALUES ($1, $2, $3, $4)
			RETURNING id, match_id, sender_id, content, msg_type, created_at
		`, matchID, senderID, in.Content, in.MsgType).Scan(
			&saved.ID, &saved.MatchID, &saved.SenderID, &saved.Content, &saved.MsgType, &saved.CreatedAt)
		if err != nil {
			return wsx.Envelope{}, errors.New("save failed")
		}

		// Increment points: +1 per message, +5 streak bonus if last activity was yesterday.
		// Recompute level via CASE so it stays consistent with thresholds.
		if _, err := ch.pool.Exec(ctx, `
			UPDATE noi_lau_progress
			SET points = points + 1 + CASE
			      WHEN last_activity IS NOT NULL
			       AND last_activity::date = (CURRENT_DATE - INTERVAL '1 day')::date
			      THEN 5 ELSE 0 END,
			    last_activity = now(),
			    level = CASE
			      WHEN points + 1 >= 100 THEN 5
			      WHEN points + 1 >= 60  THEN 4
			      WHEN points + 1 >= 30  THEN 3
			      WHEN points + 1 >= 10  THEN 2
			      ELSE 1
			    END
			WHERE match_id = $1
		`, matchID); err != nil {
			// Logging here would be nice but we don't want to fail the message.
			_ = err
		}

		payload, _ := json.Marshal(saved)
		return wsx.Envelope{Type: "message", Payload: payload}, nil
	}
	return wsx.Envelope{}, errors.New("unknown type")
}

func (ch *Chat) userInMatch(ctx context.Context, matchID, uid uuid.UUID) bool {
	var ok bool
	_ = ch.pool.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM matches
			WHERE id = $1 AND (user_a_id = $2 OR user_b_id = $2))
	`, matchID, uid).Scan(&ok)
	return ok
}

// WSAuth runs JWT auth, validates the user is in the match, and only then
// chains to the WS upgrade. We validate inline (not via JWT middleware) so the
// handler chain isn't double-invoked.
func (ch *Chat) WSAuth(secret []byte) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := middleware.ValidateBearer(c, secret); err != nil {
			return err
		}
		matchID, err := uuid.Parse(c.Params("matchId"))
		if err != nil {
			return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid match id")
		}
		uid := middleware.UserID(c)

		ctx, cancel := context.WithTimeout(c.UserContext(), 5*time.Second)
		defer cancel()
		if !ch.userInMatch(ctx, matchID, uid) {
			return models.Err(c, fiber.StatusNotFound, models.ErrMatchNotFound, "match not found")
		}

		c.Locals("match_id", matchID)
		c.Locals("user_id", uid)
		if !websocket.IsWebSocketUpgrade(c) {
			return fiber.ErrUpgradeRequired
		}
		return c.Next()
	}
}
