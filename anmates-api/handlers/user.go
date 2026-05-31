package handlers

import (
	"context"
	"strings"
	"time"

	"github.com/anmates/api/internal/httputil"
	"github.com/anmates/api/middleware"
	"github.com/anmates/api/services"
	"github.com/gofiber/fiber/v2"
)

type User struct {
	svc services.UserServicer
}

func NewUser(svc services.UserServicer) *User { return &User{svc: svc} }

func (u *User) GetProfile(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	user, err := u.svc.GetProfile(ctx, uid)
	if err != nil {
		return httputil.Err(c, fiber.StatusNotFound, httputil.ErrNotFound, "user not found")
	}
	return httputil.OK(c, toUserOut(user))
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
		return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "invalid body")
	}
	if r.Name != nil {
		trim := strings.TrimSpace(*r.Name)
		if trim == "" {
			return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "name must not be empty")
		}
		r.Name = &trim
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	user, err := u.svc.UpdateProfile(ctx, uid, r.Name, r.AvatarURL, r.Bio)
	if err != nil {
		return httputil.Err(c, fiber.StatusInternalServerError, httputil.ErrInternal, "update failed")
	}
	return httputil.OK(c, toUserOut(user))
}

type onboardingProfileReq struct {
	Name             string `json:"name"`
	Nickname         string `json:"nickname"`
	BirthDate        string `json:"birth_date"` // "YYYY-MM-DD"
	PersonalityScore *int16 `json:"personality_score"`
}

// UpdateOnboarding handles PATCH /profile/onboarding (Screen 08).
func (u *User) UpdateOnboarding(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r onboardingProfileReq
	if err := c.BodyParser(&r); err != nil {
		return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "invalid body")
	}
	r.Name = strings.TrimSpace(r.Name)
	r.Nickname = strings.TrimSpace(r.Nickname)
	if r.Name == "" {
		return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "name must not be empty")
	}

	var birthDate *time.Time
	if strings.TrimSpace(r.BirthDate) != "" {
		t, err := time.Parse("2006-01-02", strings.TrimSpace(r.BirthDate))
		if err != nil {
			return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "birth_date must be YYYY-MM-DD")
		}
		birthDate = &t
	}

	if r.PersonalityScore != nil {
		v := *r.PersonalityScore
		if v < 0 {
			v = 0
		}
		if v > 100 {
			v = 100
		}
		r.PersonalityScore = &v
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	user, err := u.svc.UpdateOnboardingProfile(ctx, uid, r.Name, r.Nickname, birthDate, r.PersonalityScore)
	if err != nil {
		return httputil.Err(c, fiber.StatusInternalServerError, httputil.ErrInternal, "update failed")
	}
	return httputil.OK(c, toUserOut(user))
}

type preferencesReq struct {
	FoodTags []string `json:"food_tags"`
	VibeTags []string `json:"vibe_tags"`
}

// UpdatePreferences handles PATCH /profile/preferences (Screen 09). Marks onboarding complete.
func (u *User) UpdatePreferences(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r preferencesReq
	if err := c.BodyParser(&r); err != nil {
		return httputil.Err(c, fiber.StatusBadRequest, httputil.ErrValidation, "invalid body")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	user, err := u.svc.UpdatePreferences(ctx, uid, r.FoodTags, r.VibeTags)
	if err != nil {
		return httputil.Err(c, fiber.StatusInternalServerError, httputil.ErrInternal, "update failed")
	}
	return httputil.OK(c, toUserOut(user))
}
