package middleware

import (
	"log/slog"
	"time"

	"github.com/gofiber/fiber/v2"
)

// RequestLogger emits one JSON line per request to the configured slog handler.
// Skips noisy WebSocket upgrade requests (they're logged at connection lifecycle).
func RequestLogger(log *slog.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()
		err := c.Next()

		path := c.Path()
		if len(path) >= 4 && path[:4] == "/ws/" {
			return err
		}

		attrs := []any{
			slog.String("method", c.Method()),
			slog.String("path", path),
			slog.Int("status", c.Response().StatusCode()),
			slog.Duration("latency", time.Since(start)),
			slog.String("ip", c.IP()),
		}
		if err != nil {
			attrs = append(attrs, slog.String("error", err.Error()))
			log.Error("http", attrs...)
			return err
		}
		log.Info("http", attrs...)
		return nil
	}
}
