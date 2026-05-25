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

// Onboarding bundles the Phase 1 onboarding endpoints:
//   POST /api/me/face-verify
//   PUT  /api/me/profile-full
//   GET  /api/me/tastes
//   PUT  /api/me/tastes
//   GET  /api/me/photos
//   POST /api/me/photos
//   DELETE /api/me/photos/:id
//
// Phase 1 keeps things simple: face-verify is a liveness-signal acceptor (no
// embedding storage), photos accept a data: URL so the picker can ship without
// S3 yet, and auto-derive (zodiac / ngu_hanh / numerology) is computed from DOB
// on the server.
type Onboarding struct {
	pool *pgxpool.Pool
}

func NewOnboarding(pool *pgxpool.Pool) *Onboarding { return &Onboarding{pool: pool} }

// ── Face verify ──────────────────────────────────────────────────────────────

type faceVerifyReq struct {
	LivenessScore float64 `json:"liveness_score"` // 0.0-1.0 client side estimate
}

func (o *Onboarding) FaceVerify(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r faceVerifyReq
	_ = c.BodyParser(&r) // body optional
	score := r.LivenessScore
	if score <= 0 {
		score = 1.0 // Phase 1 stub: accept if client says liveness passed
	}
	if score < 0.5 {
		return models.Err(c, fiber.StatusBadRequest, "FACE_LIVENESS_FAILED",
			"liveness score quá thấp — thử lại nha")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 10*time.Second)
	defer cancel()

	if _, err := o.pool.Exec(ctx, `
		INSERT INTO identity_verifications (user_id, verified_at, liveness_score)
		VALUES ($1, now(), $2)
		ON CONFLICT (user_id) DO UPDATE SET
			verified_at  = EXCLUDED.verified_at,
			liveness_score = EXCLUDED.liveness_score,
			last_redo_at = now()
	`, uid, score); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"không lưu được kết quả xác minh")
	}

	if _, err := o.pool.Exec(ctx, `
		UPDATE users SET onboarding_step = 'face_verified'
		WHERE id = $1 AND onboarding_step IN ('pending')
	`, uid); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"không cập nhật được tiến độ")
	}

	return models.OK(c, fiber.Map{
		"verified":         true,
		"liveness_score":   score,
		"onboarding_step":  "face_verified",
	})
}

// ── Profile (extended) ───────────────────────────────────────────────────────

type profileFullReq struct {
	Name              *string `json:"name"`
	Nickname          *string `json:"nickname"`
	DOB               *string `json:"dob"` // YYYY-MM-DD
	PersonalityScore  *int    `json:"personality_score"`
	ShowDerivedPublic *bool   `json:"show_derived_public"`
}

type profileFullOut struct {
	ID                string  `json:"id"`
	Name              string  `json:"name"`
	Nickname          *string `json:"nickname"`
	DOB               *string `json:"dob"`
	PersonalityScore  int     `json:"personality_score"`
	Zodiac            *string `json:"zodiac"`
	NguHanh           *string `json:"ngu_hanh"`
	Numerology        *string `json:"numerology"`
	ShowDerivedPublic bool    `json:"show_derived_public"`
	OnboardingStep    string  `json:"onboarding_step"`
}

func (o *Onboarding) PutProfileFull(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r profileFullReq
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}

	var (
		dob        *time.Time
		zodiac     *string
		nguHanh    *string
		numerology *string
	)
	if r.DOB != nil && *r.DOB != "" {
		t, err := time.Parse("2006-01-02", *r.DOB)
		if err != nil {
			return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
				"DOB phải định dạng YYYY-MM-DD")
		}
		dob = &t
		z := deriveZodiac(t)
		n := deriveNguHanh(t)
		num := deriveNumerology(t)
		zodiac = &z
		nguHanh = &n
		numerology = &num
	}

	if r.Name != nil {
		s := strings.TrimSpace(*r.Name)
		if s == "" {
			return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
				"tên không được trống")
		}
		r.Name = &s
	}
	if r.Nickname != nil {
		s := strings.TrimSpace(*r.Nickname)
		r.Nickname = &s
	}
	if r.PersonalityScore != nil && (*r.PersonalityScore < 0 || *r.PersonalityScore > 100) {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
			"personality_score phải trong [0,100]")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var out profileFullOut
	var dobOut *time.Time
	err := o.pool.QueryRow(ctx, `
		UPDATE users SET
			name                 = COALESCE($2, name),
			nickname             = COALESCE($3, nickname),
			dob                  = COALESCE($4, dob),
			personality_score    = COALESCE($5, personality_score),
			zodiac               = COALESCE($6, zodiac),
			ngu_hanh             = COALESCE($7, ngu_hanh),
			numerology           = COALESCE($8, numerology),
			show_derived_public  = COALESCE($9, show_derived_public),
			onboarding_step      = CASE
				WHEN onboarding_step IN ('pending','face_verified') THEN 'profile'
				ELSE onboarding_step
			END
		WHERE id = $1
		RETURNING id::text, name, nickname, dob, personality_score, zodiac,
			ngu_hanh, numerology, show_derived_public, onboarding_step
	`, uid, r.Name, r.Nickname, dob, r.PersonalityScore,
		zodiac, nguHanh, numerology, r.ShowDerivedPublic).Scan(
		&out.ID, &out.Name, &out.Nickname, &dobOut, &out.PersonalityScore,
		&out.Zodiac, &out.NguHanh, &out.Numerology, &out.ShowDerivedPublic,
		&out.OnboardingStep,
	)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"update profile failed: "+err.Error())
	}
	if dobOut != nil {
		s := dobOut.Format("2006-01-02")
		out.DOB = &s
	}

	return models.OK(c, out)
}

// ── Tastes ───────────────────────────────────────────────────────────────────

type tastesReq struct {
	Cuisine []string `json:"cuisine_tags"`
	Vibe    []string `json:"vibe_tags"`
}

type tastesOut struct {
	Cuisine        []string `json:"cuisine_tags"`
	Vibe           []string `json:"vibe_tags"`
	OnboardingStep string   `json:"onboarding_step"`
}

func (o *Onboarding) GetTastes(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 10*time.Second)
	defer cancel()

	var out tastesOut
	err := o.pool.QueryRow(ctx, `
		SELECT
			COALESCE(t.cuisine_tags, '{}'),
			COALESCE(t.vibe_tags, '{}'),
			u.onboarding_step
		FROM users u
		LEFT JOIN user_tastes t ON t.user_id = u.id
		WHERE u.id = $1
	`, uid).Scan(&out.Cuisine, &out.Vibe, &out.OnboardingStep)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"tastes load failed")
	}
	return models.OK(c, out)
}

func (o *Onboarding) PutTastes(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r tastesReq
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}
	if r.Cuisine == nil {
		r.Cuisine = []string{}
	}
	if r.Vibe == nil {
		r.Vibe = []string{}
	}
	if len(r.Cuisine) < 5 {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
			"chọn ít nhất 5 thẻ ẩm thực")
	}
	if len(r.Vibe) < 1 {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation,
			"chọn ít nhất 1 thẻ vibe")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 10*time.Second)
	defer cancel()

	if _, err := o.pool.Exec(ctx, `
		INSERT INTO user_tastes (user_id, cuisine_tags, vibe_tags, updated_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (user_id) DO UPDATE SET
			cuisine_tags = EXCLUDED.cuisine_tags,
			vibe_tags    = EXCLUDED.vibe_tags,
			updated_at   = now()
	`, uid, r.Cuisine, r.Vibe); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"tastes save failed")
	}

	if _, err := o.pool.Exec(ctx, `
		UPDATE users SET onboarding_step = 'tastes'
		WHERE id = $1 AND onboarding_step IN ('pending','face_verified','profile')
	`, uid); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"update onboarding step failed")
	}

	return models.OK(c, tastesOut{
		Cuisine:        r.Cuisine,
		Vibe:           r.Vibe,
		OnboardingStep: "tastes",
	})
}

// ── Photos ───────────────────────────────────────────────────────────────────

type photoIn struct {
	URL    string `json:"url"`     // data: URL or remote URL
	IsMain bool   `json:"is_main"`
}

type photoOut struct {
	ID       string `json:"id"`
	URL      string `json:"url"`
	IsMain   bool   `json:"is_main"`
	OrderIdx int    `json:"order_idx"`
}

func (o *Onboarding) GetPhotos(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 10*time.Second)
	defer cancel()

	rows, err := o.pool.Query(ctx, `
		SELECT id::text, url, is_main, order_idx
		FROM user_photos
		WHERE user_id = $1
		ORDER BY order_idx ASC, created_at ASC
	`, uid)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"photos load failed")
	}
	defer rows.Close()

	out := make([]photoOut, 0, 3)
	for rows.Next() {
		var p photoOut
		if err := rows.Scan(&p.ID, &p.URL, &p.IsMain, &p.OrderIdx); err != nil {
			continue
		}
		out = append(out, p)
	}
	return models.OK(c, out)
}

func (o *Onboarding) PostPhoto(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	var r photoIn
	if err := c.BodyParser(&r); err != nil {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "invalid body")
	}
	if strings.TrimSpace(r.URL) == "" {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "url required")
	}
	// Loose data: URL size guard ~6MB encoded.
	if len(r.URL) > 8_000_000 {
		return models.Err(c, fiber.StatusRequestEntityTooLarge, "PHOTO_TOO_LARGE",
			"ảnh hơi nặng — chọn ảnh nhỏ hơn 6MB nhé")
	}

	ctx, cancel := context.WithTimeout(c.UserContext(), 30*time.Second)
	defer cancel()

	var count int
	if err := o.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM user_photos WHERE user_id = $1`, uid,
	).Scan(&count); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"photo count failed")
	}
	if count >= 3 {
		return models.Err(c, fiber.StatusBadRequest, "PHOTO_LIMIT",
			"đã đủ 3 ảnh — xoá bớt mới upload thêm được")
	}

	// If is_main requested, unset any existing main first.
	if r.IsMain {
		if _, err := o.pool.Exec(ctx,
			`UPDATE user_photos SET is_main = false WHERE user_id = $1`, uid,
		); err != nil {
			return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
				"unset main failed")
		}
	}
	// First photo is implicitly main.
	if count == 0 {
		r.IsMain = true
	}

	orderIdx := count
	var out photoOut
	err := o.pool.QueryRow(ctx, `
		INSERT INTO user_photos (user_id, url, is_main, order_idx)
		VALUES ($1, $2, $3, $4)
		RETURNING id::text, url, is_main, order_idx
	`, uid, r.URL, r.IsMain, orderIdx).Scan(
		&out.ID, &out.URL, &out.IsMain, &out.OrderIdx,
	)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"photo insert failed: "+err.Error())
	}

	// If user just hit 1+ photo, advance onboarding_step.
	if _, err := o.pool.Exec(ctx, `
		UPDATE users SET onboarding_step = CASE
			WHEN (SELECT COUNT(*) FROM user_photos WHERE user_id = $1) >= 1
			  AND onboarding_step IN ('pending','face_verified','profile','tastes')
			THEN 'photos'
			ELSE onboarding_step
		END
		WHERE id = $1
	`, uid); err != nil {
		// non-fatal
		_ = err
	}

	return models.OK(c, out)
}

func (o *Onboarding) DeletePhoto(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	id := c.Params("id")
	if id == "" {
		return models.Err(c, fiber.StatusBadRequest, models.ErrValidation, "id required")
	}
	ctx, cancel := context.WithTimeout(c.UserContext(), 10*time.Second)
	defer cancel()
	tag, err := o.pool.Exec(ctx,
		`DELETE FROM user_photos WHERE id = $1 AND user_id = $2`, id, uid,
	)
	if err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"delete failed")
	}
	if tag.RowsAffected() == 0 {
		return models.Err(c, fiber.StatusNotFound, models.ErrNotFound, "photo not found")
	}
	return models.OK(c, fiber.Map{"deleted": true})
}

// ── Onboarding state ────────────────────────────────────────────────────────

func (o *Onboarding) FinishOnboarding(c *fiber.Ctx) error {
	uid := middleware.UserID(c)
	ctx, cancel := context.WithTimeout(c.UserContext(), 5*time.Second)
	defer cancel()
	if _, err := o.pool.Exec(ctx,
		`UPDATE users SET onboarding_step = 'done' WHERE id = $1`, uid,
	); err != nil {
		return models.Err(c, fiber.StatusInternalServerError, models.ErrInternal,
			"update onboarding step failed")
	}
	return models.OK(c, fiber.Map{"onboarding_step": "done"})
}

// ── Derived helpers ─────────────────────────────────────────────────────────

// deriveZodiac returns the Vietnamese name of the Western zodiac for the date.
func deriveZodiac(t time.Time) string {
	m := int(t.Month())
	d := t.Day()
	switch {
	case (m == 3 && d >= 21) || (m == 4 && d <= 19):
		return "Bạch Dương"
	case (m == 4 && d >= 20) || (m == 5 && d <= 20):
		return "Kim Ngưu"
	case (m == 5 && d >= 21) || (m == 6 && d <= 20):
		return "Song Tử"
	case (m == 6 && d >= 21) || (m == 7 && d <= 22):
		return "Cự Giải"
	case (m == 7 && d >= 23) || (m == 8 && d <= 22):
		return "Sư Tử"
	case (m == 8 && d >= 23) || (m == 9 && d <= 22):
		return "Xử Nữ"
	case (m == 9 && d >= 23) || (m == 10 && d <= 22):
		return "Thiên Bình"
	case (m == 10 && d >= 23) || (m == 11 && d <= 21):
		return "Bọ Cạp"
	case (m == 11 && d >= 22) || (m == 12 && d <= 21):
		return "Nhân Mã"
	case (m == 12 && d >= 22) || (m == 1 && d <= 19):
		return "Ma Kết"
	case (m == 1 && d >= 20) || (m == 2 && d <= 18):
		return "Bảo Bình"
	default:
		return "Song Ngư"
	}
}

// deriveNguHanh maps the Vietnamese sexagenary cycle year to its element name.
// Lookup table covers 1924-2043 (Giáp Tý → Quý Hợi cycle).
func deriveNguHanh(t time.Time) string {
	// 60-year cycle elements (paired). Index = (year - 1924) mod 60.
	// Source: standard "60 hoa giáp" table.
	elements := []string{
		"Hải Trung Kim", "Hải Trung Kim", // 1924,1925
		"Lư Trung Hỏa", "Lư Trung Hỏa",
		"Đại Lâm Mộc", "Đại Lâm Mộc",
		"Lộ Bàng Thổ", "Lộ Bàng Thổ",
		"Kiếm Phong Kim", "Kiếm Phong Kim",
		"Sơn Đầu Hỏa", "Sơn Đầu Hỏa",
		"Giản Hạ Thủy", "Giản Hạ Thủy",
		"Thành Đầu Thổ", "Thành Đầu Thổ",
		"Bạch Lạp Kim", "Bạch Lạp Kim",
		"Dương Liễu Mộc", "Dương Liễu Mộc",
		"Tuyền Trung Thủy", "Tuyền Trung Thủy",
		"Ốc Thượng Thổ", "Ốc Thượng Thổ",
		"Tích Lịch Hỏa", "Tích Lịch Hỏa",
		"Tùng Bách Mộc", "Tùng Bách Mộc",
		"Trường Lưu Thủy", "Trường Lưu Thủy",
		"Sa Trung Kim", "Sa Trung Kim",
		"Sơn Hạ Hỏa", "Sơn Hạ Hỏa",
		"Bình Địa Mộc", "Bình Địa Mộc",
		"Bích Thượng Thổ", "Bích Thượng Thổ",
		"Kim Bạc Kim", "Kim Bạc Kim",
		"Phú Đăng Hỏa", "Phú Đăng Hỏa",
		"Thiên Hà Thủy", "Thiên Hà Thủy",
		"Đại Trạch Thổ", "Đại Trạch Thổ",
		"Thoa Xuyến Kim", "Thoa Xuyến Kim",
		"Tang Đố Mộc", "Tang Đố Mộc",
		"Đại Khê Thủy", "Đại Khê Thủy",
		"Sa Trung Thổ", "Sa Trung Thổ",
		"Thiên Thượng Hỏa", "Thiên Thượng Hỏa",
		"Thạch Lựu Mộc", "Thạch Lựu Mộc",
		"Đại Hải Thủy", "Đại Hải Thủy",
	}
	y := t.Year()
	idx := ((y - 1924) % 60 + 60) % 60
	return elements[idx]
}

// deriveNumerology returns the Pythagorean life-path number (1-9, 11, 22, 33)
// computed from the full DOB.
func deriveNumerology(t time.Time) string {
	digits := []int{}
	year := t.Year()
	month := int(t.Month())
	day := t.Day()
	for _, n := range []int{year, month, day} {
		for n > 0 {
			digits = append(digits, n%10)
			n /= 10
		}
	}
	sum := 0
	for _, d := range digits {
		sum += d
	}
	// Reduce, preserving master numbers.
	reduce := func(n int) int {
		for n > 9 && n != 11 && n != 22 && n != 33 {
			s := 0
			for n > 0 {
				s += n % 10
				n /= 10
			}
			n = s
		}
		return n
	}
	life := reduce(sum)
	// Friendly labels for common numbers.
	switch life {
	case 1:
		return "Số 1 · Tiên phong"
	case 2:
		return "Số 2 · Hài hoà"
	case 3:
		return "Số 3 · Sáng tạo"
	case 4:
		return "Số 4 · Kiên định"
	case 5:
		return "Số 5 · Tự do · Phiêu lưu"
	case 6:
		return "Số 6 · Ân cần"
	case 7:
		return "Số 7 · Nội tâm"
	case 8:
		return "Số 8 · Quyết đoán"
	case 9:
		return "Số 9 · Vị tha"
	case 11:
		return "Số 11 · Trực giác"
	case 22:
		return "Số 22 · Kiến tạo"
	case 33:
		return "Số 33 · Bậc thầy"
	default:
		return "Số đặc biệt"
	}
}
