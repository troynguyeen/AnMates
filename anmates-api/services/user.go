package services

import (
	"context"
	"time"

	"github.com/anmates/api/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserService struct {
	pool *pgxpool.Pool
}

func NewUserService(pool *pgxpool.Pool) *UserService { return &UserService{pool: pool} }

// userColumns is the shared SELECT/RETURNING projection so every read of a user
// row scans the same fields in the same order.
const userColumns = `id, name, email, phone, avatar_url, bio,
	nickname, birth_date, personality_score, food_tags, vibe_tags, onboarding_done`

// scanUser scans a row produced by userColumns into u.
func scanUser(row interface {
	Scan(dest ...any) error
}, u *models.User) error {
	return row.Scan(
		&u.ID, &u.Name, &u.Email, &u.Phone, &u.AvatarURL, &u.Bio,
		&u.Nickname, &u.BirthDate, &u.PersonalityScore, &u.FoodTags, &u.VibeTags, &u.OnboardingDone,
	)
}

func (s *UserService) GetProfile(ctx context.Context, userID uuid.UUID) (*models.User, error) {
	var u models.User
	err := scanUser(s.pool.QueryRow(ctx, `
		SELECT `+userColumns+` FROM users WHERE id = $1
	`, userID), &u)
	if err != nil {
		return nil, ErrNotFound
	}
	return &u, nil
}

func (s *UserService) UpdateProfile(ctx context.Context, userID uuid.UUID, name, avatarURL, bio *string) (*models.User, error) {
	var u models.User
	err := scanUser(s.pool.QueryRow(ctx, `
		UPDATE users SET
			name       = COALESCE($2, name),
			avatar_url = COALESCE($3, avatar_url),
			bio        = COALESCE($4, bio)
		WHERE id = $1
		RETURNING `+userColumns+`
	`, userID, name, avatarURL, bio), &u)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// UpdateOnboardingProfile persists Screen 08 data (name, nickname, DOB, personality).
func (s *UserService) UpdateOnboardingProfile(ctx context.Context, userID uuid.UUID, name, nickname string, birthDate *time.Time, personalityScore *int16) (*models.User, error) {
	var u models.User
	err := scanUser(s.pool.QueryRow(ctx, `
		UPDATE users SET
			name              = COALESCE(NULLIF($2, ''), name),
			nickname          = NULLIF($3, ''),
			birth_date        = $4,
			personality_score = $5
		WHERE id = $1
		RETURNING `+userColumns+`
	`, userID, name, nickname, birthDate, personalityScore), &u)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// UpdatePreferences persists Screen 09 data (food + vibe tags) and marks
// onboarding complete.
func (s *UserService) UpdatePreferences(ctx context.Context, userID uuid.UUID, foodTags, vibeTags []string) (*models.User, error) {
	if foodTags == nil {
		foodTags = []string{}
	}
	if vibeTags == nil {
		vibeTags = []string{}
	}
	var u models.User
	err := scanUser(s.pool.QueryRow(ctx, `
		UPDATE users SET
			food_tags       = $2,
			vibe_tags       = $3,
			onboarding_done = TRUE
		WHERE id = $1
		RETURNING `+userColumns+`
	`, userID, foodTags, vibeTags), &u)
	if err != nil {
		return nil, err
	}
	return &u, nil
}
