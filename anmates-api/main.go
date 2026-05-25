package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/anmates/api/config"
	"github.com/anmates/api/db"
	"github.com/anmates/api/handlers"
	"github.com/anmates/api/middleware"
	"github.com/anmates/api/models"
	"github.com/anmates/api/ws"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func logLevel() slog.Level {
	switch strings.ToLower(os.Getenv("LOG_LEVEL")) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

func main() {
	log := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: logLevel()}))
	slog.SetDefault(log)

	cfg, err := config.Load()
	if err != nil {
		log.Error("config", "err", err)
		os.Exit(1)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	pool, err := db.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Error("db pool", "err", err)
		os.Exit(1)
	}
	defer pool.Close()

	if err := db.Migrate(ctx, pool); err != nil {
		log.Error("migrate", "err", err)
		os.Exit(1)
	}
	log.Info("migrations applied")

	hub := ws.NewHub()
	app := fiber.New(fiber.Config{
		AppName:               "anmates-api",
		DisableStartupMessage: true,
		ReadTimeout:           15 * time.Second,
		WriteTimeout:          15 * time.Second,
		IdleTimeout:           60 * time.Second,
		BodyLimit:             4 * 1024 * 1024,
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if fe, ok := err.(*fiber.Error); ok {
				code = fe.Code
			}
			return models.Err(c, code, models.ErrInternal, err.Error())
		},
	})

	app.Use(recover.New())
	app.Use(func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Content-Type,Authorization")
		if c.Method() == fiber.MethodOptions {
			return c.SendStatus(fiber.StatusNoContent)
		}
		return c.Next()
	})
	app.Use(middleware.RequestLogger(log))

	rl := middleware.NewRateLimit(0.5, 5)
	rateLimitOff := os.Getenv("DISABLE_RATE_LIMIT") == "1" || os.Getenv("DISABLE_RATE_LIMIT") == "true"
	if rateLimitOff {
		log.Warn("DISABLE_RATE_LIMIT set — rate limiter is OFF")
	}
	rlHandler := func(c *fiber.Ctx) error { return c.Next() }
	if !rateLimitOff {
		rlHandler = rl.Handler()
	}

	authH := handlers.NewAuth(pool, cfg)
	userH := handlers.NewUser(pool)
	wlH := handlers.NewWishlist(pool)
	matchH := handlers.NewMatching(pool)
	chatH := handlers.NewChat(pool, hub)
	noiH := handlers.NewNoiLau(pool)
	onbH := handlers.NewOnboarding(pool)
	jwtMW := middleware.JWT(cfg.JWTSecret)

	app.Get("/health", func(c *fiber.Ctx) error {
		ctx, cancel := context.WithTimeout(c.UserContext(), 2*time.Second)
		defer cancel()
		if err := pool.Ping(ctx); err != nil {
			return models.Err(c, fiber.StatusServiceUnavailable, models.ErrInternal, "db down")
		}
		return models.OK(c, fiber.Map{"status": "ok"})
	})

	api := app.Group("/api", rlHandler)

	// Auth (public).
	api.Post("/auth/register", authH.Register)
	api.Post("/auth/login", authH.Login)
	api.Post("/auth/phone-verify", authH.PhoneVerify)
	api.Post("/auth/refresh", authH.Refresh)
	api.Post("/auth/logout", authH.Logout)
	if cfg.DevMode {
		api.Post("/auth/dev-login", authH.DevLogin)
		log.Warn("DEV_MODE on — /api/auth/dev-login is open (requires DEV_BYPASS_SECRET)")
	}

	// Authenticated.
	auth := api.Use(jwtMW)
	auth.Get("/profile", userH.GetProfile)
	auth.Put("/profile", userH.UpdateProfile)

	// Onboarding (Phase 1)
	auth.Post("/me/face-verify", onbH.FaceVerify)
	auth.Put("/me/profile-full", onbH.PutProfileFull)
	auth.Get("/me/tastes", onbH.GetTastes)
	auth.Put("/me/tastes", onbH.PutTastes)
	auth.Get("/me/photos", onbH.GetPhotos)
	auth.Post("/me/photos", onbH.PostPhoto)
	auth.Delete("/me/photos/:id", onbH.DeletePhoto)
	auth.Post("/me/onboarding/finish", onbH.FinishOnboarding)

	auth.Get("/wishlist", wlH.List)
	auth.Post("/wishlist", wlH.Create)
	auth.Delete("/wishlist/:id", wlH.Delete)

	auth.Get("/matches", matchH.List)
	auth.Post("/matches/:id/accept", matchH.Accept)
	auth.Get("/conversations", matchH.Conversations)
	auth.Get("/matches/:id/messages", chatH.History)
	auth.Get("/matches/:id/progress", noiH.Get)

	// WebSocket chat — auth + upgrade-required check, then the WS handler.
	app.Get("/ws/chat/:matchId", chatH.WSAuth(cfg.JWTSecret), chatH.WebSocket())

	// Graceful shutdown.
	go func() {
		sig := make(chan os.Signal, 1)
		signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
		<-sig
		log.Info("shutdown signal received")
		hub.CloseAll()
		shutCtx, shutCancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer shutCancel()
		if err := app.ShutdownWithContext(shutCtx); err != nil {
			log.Error("shutdown", "err", err)
		}
		cancel()
	}()

	log.Info("listening", "port", cfg.Port)
	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Error("listen", "err", err)
		os.Exit(1)
	}
}
