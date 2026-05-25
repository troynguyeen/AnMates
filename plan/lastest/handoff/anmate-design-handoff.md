# ĂnMates · Phase 1 — Product Requirements & Engineering Handoff

> **Tác giả:** Product · **Ngày:** 25.05.2026 · **Phiên bản:** 1.0
> **Đối tượng đọc:** Engineering, QA, Design, Trust & Safety, Ops
> **Trạng thái:** Ready for sprint planning

---

## 0. TL;DR — Đọc 60 giây

ĂnMates **Phase 1 launch dưới dạng "Ultimate-for-all"**: mọi user sau khi xác minh đều dùng được **toàn bộ tính năng** của app, không có tier, không có paywall, không có IAP. Mục tiêu là tối đa hoá retention + dữ liệu hành vi trong 8 tuần đầu để chuẩn bị cho Phase 2 (monetisation).

- **Có trong Phase 1:** Onboarding · Khám phá · Wishlist · Dining swipe · Match · Chat (Vibe meter) · First Date scheduling · Selfie xuất phát · Live Tracking · Auto check-in · Đánh giá ẩn danh · Trust Score (như một score đo lường, không gating) · Tab Mình · Block · Report · Cancel · Xoá tài khoản.
- **Tắt trong Phase 1:** Toàn bộ surface IAP (3 màn gói) · Trust Booster · Instant Amnesty · Trust Freeze · Golden Match Pool · Ghost Tracking · Deal Radar · Cashback · Forgiveness · Peak Hour Priority · Vibe ×1.5 multiplier · Point ×1.2 · Profile badge tier.
- **Vẫn hiển thị nhưng ở chế độ "Coming soon":** Mục "Gói ĂnMates" ở tab Mình → một entry duy nhất nói "Mọi tính năng ĂnMates đang mở miễn phí trong giai đoạn ra mắt. Gói VIP sẽ xuất hiện sau" + CTA "Đăng ký nhận tin khi gói ra mắt".

**Lý do của quyết định:**
1. Loại bỏ rào cản tiếp nhận khi user base còn nhỏ.
2. Cần lượng dữ liệu hành vi (Vibe, Trust event, completion rate) để định cỡ các perk tier ở Phase 2 dựa trên số thật, không dựa vào giả định.
3. Giảm độ phức tạp launch — ít surface = ít bug.

---

## 1. Mục tiêu Phase 1 & KPI

### 1.1 Business goal
Chứng minh **place-first matching** có market fit ở TP.HCM trước khi mở rộng.

### 1.2 KPI (8 tuần đầu sau launch)

| Metric | Mục tiêu | Cách đo |
|---|---|---|
| Activation rate | ≥60% user qua hết onboarding (B6) | event `signup_complete` |
| D7 retention | ≥35% | session_open trong ngày 7 |
| First match → first chat | ≥80% trong 24h | timestamp delta |
| Vibe ≥70 / chat đã start | ≥25% | snapshot match.vibe |
| First Date confirmed → check-in cả hai | ≥70% | event `booking_both_checked_in` |
| Trust event volume / WAU | ≥0.4 | tổng trust_event / WAU |
| Review submit rate | ≥65% | review_submitted / completed_booking |
| Crash-free sessions | ≥99.5% | Crashlytics |

### 1.3 Non-goal Phase 1
- Không build IAP / billing / receipt validation.
- Không build admin tier-management UI.
- Không build group dining (≥3 Mate).
- Không support đa ngôn ngữ (VN-only).
- Không support tablet/desktop.

---

## 2. Scope chi tiết

### 2.1 Trong scope (build & ship)

#### A · Onboarding (Màn 01–10)
- [x] Splash với loader copy.
- [x] 3 màn edu (có "Bỏ qua" từng màn).
- [x] Nhập số điện thoại VN (+84).
- [x] OTP 6 số, TTL 90s, max 5 attempts/request, rate-limit 3 request / 15 phút / số.
- [x] Face verify với liveness on-device + chống replay phía server.
- [x] Profile cơ bản (tên, nickname, DOB, slider tính cách).
- [x] Auto-derive cung / ngũ hành / numerology (read-only, có toggle "không hiển thị" cho profile public).
- [x] Gu ẩm thực (≥5 thẻ cuisine + ≥1 thẻ vibe).
- [x] Upload ảnh (≤3, có ảnh main, NSFW + face check, OCR phone/URL).
- [x] Apple ID login alternative (skip phone+OTP nhưng vẫn face + profile).

#### B · Khám phá (Màn 09 Home)
- [x] Greeting theo tên user + quận hiện tại.
- [x] Search bar (text + voice — voice resolve thành genre/vibe tag).
- [x] Genre tile rail.
- [x] Vibe tile rail.
- [x] "Hot quanh bạn" theo khung giờ (re-rank mỗi 15 phút).
- [x] Bottom nav 4 tab: Khám phá · Wishlist · Chat · Mình.

#### C · Chi tiết quán (Màn 11)
- [x] Hero image, rating, distance, price range.
- [x] % hợp gu (overlap gu + vibe).
- [x] Vibe tag breakdown (Cay 3 ✓ · Không hành ✓ · ...).
- [x] CTA "＋ Wishlist".
- [x] CTA "Tìm Mate ăn cùng ↗".
- [x] "X người quanh đây cũng đang thèm quán này" (live count).

#### D · Dining swipe (Màn 12)
- [x] Deck scope theo quán (rời quán → reset).
- [x] Thẻ Mate: ảnh, tên, tuổi, Trust badge, distance, status quip, tag gu.
- [x] Chip "Cũng vừa thêm quán này · N phút trước".
- [x] Quẹt phải / trái / lên (super-like).
- [x] Cooldown đã-pass: 24h / cặp user-quán.

#### E · Match & Chat (Màn 13–16)
- [x] Match screen full-bleed.
- [x] 24h hello window (auto-archive nếu zero tin).
- [x] Inbox 4 nhóm: Mới match · Đang tám · Best Mate · Hôm qua.
- [x] **Phòng chat không giới hạn cho mọi user** (xem §3.1).
- [x] Vibe meter 0–100 với threshold 70.
- [x] Chip gợi ý chat (Topping tủ? / Có order bia? / Khung giờ tiện?).
- [x] Voice note (press-hold + cancel-by-slide).
- [x] Auto-redact SĐT / Zalo / Telegram trong chat.
- [x] First Date CTA mở khi Vibe ≥70.

#### F · First Date (Màn 17)
- [x] Calendar grid tháng + chip 7 ngày + slot giờ.
- [x] Quán prefilled từ match context.
- [x] Voucher 50k "vì chốt nhanh" hiển thị có điều kiện (cả hai check-in đúng giờ).
- [x] Booking state machine: `pending` → `confirmed` | `declined` | `cancelled`.
- [x] Soft-hold bàn 15 phút khi pending.
- [x] Sync Calendar máy (iOS Calendar / Google Calendar).

#### G · Ngày hẹn (Màn 20–21)
- [x] Push T-45 phút "Lên đường với [Mate]".
- [x] Selfie xuất phát: liveness, sticker/text/mood/chip/emoji overlay, không upload từ library.
- [x] 3 nút: Xác nhận đi · Báo trễ (5/10/15+ phút) · Nhắc lại 5 phút (max 3 lần).
- [x] Live Tracking card abstract (ETA + status), KHÔNG dùng full map.
- [x] Auto check-in qua geofence (polygon chính xác, không phải bán kính).
- [x] Notification proximity (320m).
- [x] Soft-check khi trễ >15' không báo trước; mark `no_show` ở T+25'.

#### H · Đánh giá ẩn danh (Màn 22)
- [x] Trigger T+30 phút sau check-in muộn hơn của hai bên.
- [x] Chip multi-select: 5 positive + 1 cautious.
- [x] Freeform ≤280 ký tự.
- [x] Optional review quán (text + photo + video).
- [x] Double-blind reveal (chỉ lộ khi cả hai submit hoặc T+48h).
- [x] "Báo cáo" → entry vào luồng safety (xem §2.1.K).

#### I · Trust Score (Màn 24)
- [x] Score 0–100, mặc định 100 lúc signup.
- [x] Ngưỡng hiển thị: ≥90 Perfect Mate (top X%), 80–89 Trusted, <80 Limited.
- [x] **Phase 1: hiển thị badge & ngưỡng nhưng KHÔNG gating bất kỳ tính năng nào.**
- [x] Sổ cái event với delta, timestamp, lý do.
- [x] Auto-forgiveness khi trễ vì tắc đường (geofence dữ liệu giao thông — best effort, có thể là V1.1).

#### J · Tab Mình (Màn 23)
- [x] Public profile preview (cung, ngũ hành, numerology nếu user bật).
- [x] Album buổi ăn, Wishlist count, Best Mates count.
- [x] Trust dashboard entry.
- [x] **Profile edit mode (P0)** — chưa có trong bộ màn, design phải bổ sung.
- [x] Settings entry (push, vị trí, ngôn ngữ, blocklist, devices).
- [x] Mục "Gói ĂnMates" → trạng thái **Coming soon** (xem §2.2).

#### K · Safety & moderation (chưa có trong bộ màn — design P0)
- [x] **Block / unmatch** — từ profile, chat header, vuốt inbox row.
- [x] **Report form** — categories: hành vi không phù hợp, ảnh giả, hăm doạ, lừa đảo, khác; upload bằng chứng.
- [x] **Pause tài khoản** trong khi T&S review.
- [x] **Cancel booking** với preview phạt Trust trước confirm.
- [x] **Xoá tài khoản + xuất dữ liệu** (compliance Nghị định 13/2023).

#### L · Wishlist (Màn 10 Wishlist)
- [x] Tách 2 sub-tab: **Quán đã lưu** · **Kèo đã đi qua** (gộp ảnh vào tab thứ 2).
- [x] Group theo quận.
- [x] Best Mates rail trong "Kèo đã đi qua".

### 2.2 Coming soon (build placeholder)

Một entry duy nhất trong Tab Mình:

```
GÓI ĂN MATES
✨ Đang mở toàn bộ tính năng miễn phí trong giai đoạn ra mắt
   Các gói VIP sẽ xuất hiện trong những bản cập nhật sắp tới.

[Đăng ký nhận tin khi gói ra mắt]
```

CTA → modal nhập email opt-in. Dữ liệu lưu vào bảng `iap_waitlist`.

### 2.3 Out of scope Phase 1 (KHÔNG build)

| Hạng mục | Lý do dời |
|---|---|
| 3 màn IAP overview/Plus/Gold/Ultimate (25–28) | Move to Phase 2 |
| Trust Booster, Amnesty, Freeze, Forgiveness | Phụ thuộc IAP |
| Golden Match Pool, Ghost Tracking, Peak Hour | Phụ thuộc IAP |
| Vibe ×1.5, Point ×1.2 multiplier | Phụ thuộc IAP |
| Deal Radar | Phụ thuộc partner pipeline + IAP |
| Cashback 100k | Phụ thuộc IAP |
| Ăn nhóm (≥3 Mate) | Phase 2 |
| Đa ngôn ngữ | Phase 3 |
| Referral / mời bạn | Phase 2 (đề xuất sớm) |

---

## 3. Logic được điều chỉnh cho Phase 1

### 3.1 Phòng chat — không giới hạn cho mọi user

**Quy tắc business:**
- Không siết số phòng chat song song.
- Auto-archive room sau **7 ngày** không có tin (Vibe đóng băng tại điểm dừng).
- 24h hello window vẫn áp dụng — không nói hello → match expire.
- Quota **technical** (chống abuse, không phải commercial): ≤200 active room / user. Vượt → server reject match mới với mã `LIMIT_ACTIVE_CHATS_TECHNICAL`, hint UI "Dọn bớt chat cũ để match mới nhé".

**Anti-spam:**
- Rate-limit match mới: ≤30 / 24h / user.
- Detect spam pattern (cùng template tin nhắn đa room) → soft-flag T&S review.

### 3.2 Vibe meter — speed cố định ×1

Không có multiplier ×1.5 trong Phase 1. Mọi user đều ×1. Logic vẫn ghi log signal (length, latency, reciprocity, media use) để Phase 2 calibrate multiplier dựa trên số thật.

### 3.3 Trust Score — đo lường, không gating

Trust vẫn được tính, vẫn hiển thị, vẫn có ngưỡng 90/80, nhưng:
- **KHÔNG** giới hạn số chat khi Trust <80.
- **KHÔNG** boost Trust qua paid amnesty/booster/freeze.
- Recovery chỉ qua hành vi tích cực: check-in đúng giờ (+2), review chi tiết kèm hình (+3), được Mate đánh giá 5★ (+1).
- Hiển thị badge ≥90 (Perfect Mate top X%) như tín hiệu xã hội.

### 3.4 Voucher 50k — vẫn có

Voucher "chốt nhanh + cả hai đúng giờ" giữ nguyên ở Phase 1 — nó nằm trên ngân sách co-marketing với quán, không phụ thuộc IAP.

### 3.5 Lá thư — quota chống spam

Mỗi user tối đa **3 Lá thư đang chờ phản hồi** đồng thời. Vượt → phải đợi expire/decline. Cùng cặp người gửi → người nhận chặn 14 ngày sau decline/expire.

---

## 4. Data model (lược đồ tối thiểu)

```
users
  id, phone_hash, apple_user_id?, dob, name, nickname,
  personality_score (0-100), created_at, last_active_at,
  status (active|paused|deleted)

profile_derived
  user_id, zodiac, ngu_hanh, numerology, show_in_public (bool)

tastes
  user_id, cuisine_tags[], vibe_tags[]

photos
  id, user_id, url, is_main, order_idx,
  nsfw_score, face_detected, ocr_phone_detected

identity_verifications
  user_id, face_embedding (vector), liveness_score,
  verified_at, last_redo_at

restaurants
  id, name, district, geo_polygon, genres[], vibes[],
  price_range, hours, status (active|closed|delisted)

wishlist
  user_id, restaurant_id, added_at

swipes
  id, swiper_id, target_id, restaurant_id, direction, created_at

matches
  id, user_a, user_b, restaurant_id, created_at,
  hello_window_until, status (active|expired|blocked|deleted)

chat_rooms
  id, match_id, vibe_score (0-100), last_message_at,
  archived_at?

messages
  id, room_id, sender_id, body, voice_url?, media_url?,
  redacted_pii (bool), created_at

vibe_events  (log để Phase 2 calibrate)
  id, room_id, message_id, delta, signals_json, created_at

letters
  id, sender_id, receiver_id, restaurant_id, body, ps_line,
  mood_chips[], proposed_at, expires_at,
  status (sent|opened|accepted|declined|expired)

bookings
  id, match_id|letter_id, restaurant_id, scheduled_at,
  status (pending|confirmed|cancelled|completed|no_show),
  voucher_eligible, soft_hold_until

booking_events
  booking_id, type (depart|late|checkin|cancel|...), actor_id,
  payload_json, created_at

reviews
  id, booking_id, reviewer_id, target_id, chips[],
  freeform_text, venue_review_text, venue_media[],
  submitted_at, revealed_at

trust_events
  id, user_id, delta, reason_code, related_booking_id?,
  created_at

reports
  id, reporter_id, target_id, category, evidence_urls[],
  status (open|investigating|resolved|dismissed), created_at

iap_waitlist                       -- Phase 1 placeholder
  email, opted_in_at, source_screen

push_tokens, sessions, device_metadata, consent_log
  -- chuẩn
```

---

## 5. API contracts (overview)

> Chi tiết schema sẽ ở OpenAPI doc riêng. Đây là danh sách endpoint Phase 1 phải support.

### Auth & onboarding
- `POST /auth/otp/request`
- `POST /auth/otp/verify`
- `POST /auth/apple`
- `POST /verify/face` (multipart, liveness)
- `POST /me/profile` (update profile + tastes + photos)
- `POST /me/photos`, `PATCH /me/photos/:id/order`, `DELETE /me/photos/:id`

### Discovery & match
- `GET /home?district=&time_slot=`
- `GET /restaurants/:id`
- `POST /wishlist/:rid`, `DELETE /wishlist/:rid`
- `GET /restaurants/:id/swipe-pool`
- `POST /swipes`
- `POST /matches/check`

### Chat
- `GET /matches/:id`
- WS `/chat/:room_id`
- `POST /messages` (server runs PII redaction)
- `GET /matches/:id/vibe`

### Letter
- `POST /letters` (rate-limit, anti-spam)
- `GET /letters/:id`
- `POST /letters/:id/respond`

### Booking
- `POST /bookings` (creates pending + soft-hold)
- `POST /bookings/:id/accept`
- `POST /bookings/:id/decline`
- `POST /bookings/:id/depart` (selfie required)
- `POST /bookings/:id/late`
- `POST /bookings/:id/checkin` (server-side via geofence + fallback manual)
- `POST /bookings/:id/cancel` (preview penalty Trust trước khi commit)
- `POST /bookings/:id/review`

### Trust & safety
- `GET /me/trust`
- `GET /me/trust/events?cursor=`
- `POST /reports`
- `POST /blocks`, `DELETE /blocks/:user_id`
- `POST /me/account/pause`, `POST /me/account/resume`
- `POST /me/account/delete` (initiates 14-day soft-delete with export)
- `GET /me/account/export` (zip blob, async job)

### Placeholder cho IAP (Phase 1)
- `POST /iap/waitlist` (email opt-in)

---

## 6. Phi-chức-năng (non-functional)

### 6.1 Performance
- App cold start ≤2.5s p75 trên iPhone 12 / Android equivalent.
- Home payload TTFB ≤400ms p95.
- WS chat reconnect ≤3s sau khi mạng quay lại.

### 6.2 Reliability
- ≥99.5% crash-free sessions.
- Chat message delivery: at-least-once, dedupe phía client theo message_id.
- Geofence check-in: idempotent (event lặp không tính 2 lần Trust).

### 6.3 An toàn & quyền riêng tư
- Selfie thô **huỷ ngay** sau khi tạo embedding.
- DOB không lộ cho user khác — chỉ derived values.
- SĐT bị mask ở mọi surface giao tiếp với Mate khác.
- Tuân thủ Nghị định 13/2023: user xuất + xoá được dữ liệu.

### 6.4 Mobile-specific
- iOS 15+ / Android 10+ (API 29).
- Permission staggering: camera tại face verify · vị trí sau Home view đầu · push sau match đầu.
- Live Tracking dùng geofence + background fetch, không foreground GPS.
- SMS auto-fill: iOS native + Android SMS Retriever API.
- Haptic + sound điểm nhấn: Match, Vibe unlock, Letter open, Auto check-in.

---

## 7. Phân quyền (Phase 1)

| Role | Quyền | Ghi chú |
|---|---|---|
| Guest | Splash + 3 màn edu | Không persistence |
| Unverified (post-OTP) | Resume onboarding | Không matching |
| Verified Mate | **Toàn bộ tính năng app** | Không tier, không paywall |
| T&S Mod | Admin tool (web, không in-app) | Pause / unpause user, resolve report |
| Customer Support | Admin tool đọc Trust ledger + adjust manual | Day-1 cần |
| Ops (catalogue) | CMS quán + voucher rules | Day-1 cần |

---

## 8. Phụ thuộc & rủi ro

### 8.1 Phụ thuộc bên thứ ba
- Apple Vision / Google ML Kit cho liveness.
- Apple SMS auto-fill / Google SMS Retriever.
- SMS gateway VN (Viettel/Vinaphone/Mobifone).
- Map provider cho geofence + ETA (Google Maps / Mapbox — chọn sớm).
- Push: APNs + FCM.
- Crash analytics: Crashlytics / Sentry.

### 8.2 Rủi ro & mitigation

| Rủi ro | Tác động | Mitigation |
|---|---|---|
| Pool quán mỏng lúc launch | Empty state liên tục → churn | Curate ≥200 quán trước D-7 ở Q1, Q3, Q5 |
| Spam chat (do không giới hạn) | Trải nghiệm xấu | Rate-limit 30 match/24h + auto-archive 7 ngày + auto-redact |
| Face verify fail rate cao | Drop-off onboarding | Fallback CMND/CCCD review thủ công (SLA ≤24h) |
| Live Tracking nuốt pin | Review xấu | Geofence + background fetch, không foreground GPS |
| Lệch counter "5 bước" onboarding | Confusion nhỏ | Đổi thành 6/6 hoặc bỏ counter ở màn face verify |

---

## 9. Câu hỏi mở (cần Product / Design xác nhận trước khi build)

1. **Voucher 50k**: ai funding — ĂnMates hay quán? Áp được cho mọi quán hay chỉ partner curated?
2. **Geofence radius vs polygon**: dữ liệu polygon mua từ đâu cho ≥200 quán curate?
3. **Trust event "+3 review có hình"**: định nghĩa "có hình" — tối thiểu 1 hình hay 2?
4. **Lá thư rate-limit**: 3 thư đang chờ là tổng hay theo người nhận?
5. **Apple ID login**: skip OTP nhưng có skip phone number capture không (cho safety contact)?
6. **Auto-forgiveness tắc đường**: có dữ liệu giao thông realtime không? Nếu không → V1.1.
7. **Email opt-in cho IAP waitlist**: dùng vendor nào (Mailchimp/Sendgrid)?
8. **Trust badge top 8%**: ngưỡng % cố định hay percentile động? Cố định khả thi hơn lúc user base nhỏ.
9. **Đa giác giờ vàng**: nếu Phase 1 không có Peak Hour Priority, surface "giờ vàng" có hiển thị không? Đề xuất: hiển thị badge quán "đang giờ vàng" nhưng không gating gì.
10. **Coming soon mục Gói ĂnMates**: có A/B test wording (`Đăng ký nhận tin` vs `Bật notify`) không?

---

## 10. Timeline đề xuất (tham khảo)

| Tuần | Track | Mốc |
|---|---|---|
| W1–2 | Foundation | Schema, auth, OTP, face verify, profile, photos |
| W3–4 | Discovery | Home, restaurant detail, wishlist, swipe pool |
| W3–4 | Chat infra | WS, message store, PII redaction, vibe meter |
| W5 | Match → chat → schedule | End-to-end happy path runnable |
| W5 | Letter | Sender composer + receiver flow |
| W6 | Day-of | Selfie, Live Tracking, geofence, auto check-in |
| W6 | Review | Anonymous double-blind + Trust event ledger |
| W7 | Safety | Block, report, cancel, pause, delete account |
| W7 | Polish | Empty/loading/error states, haptic, accessibility pass |
| W8 | Hardening | Crash budget, perf, store submission |

**Soft-launch D1:** 1 quận (Q1), 200 user closed beta.
**Public launch D+14:** 5 quận (Q1, Q3, Q5, Q7, Bình Thạnh).

---

## 11. Định nghĩa "Done" cho Phase 1

Một feature được coi là done khi:
1. UI khớp design spec ở mọi state (default, loading, empty, error, success).
2. API có OpenAPI doc + integration test.
3. Analytics event được fire đúng (xem analytics spec riêng).
4. Localization: 100% string đi qua VN dictionary, không hard-code.
5. Accessibility: dynamic type, screen-reader label cho element tương tác, contrast ≥AA.
6. QA: regression pass trên iPhone 12, iPhone 15, Pixel 7, Samsung A54.
7. Crashlytics 0 P0 issue, ≤3 P1 đang đợi fix.

---

## 12. Appendix

### A · Mapping màn ↔ feature ↔ design reference ↔ priority

> **Cách dùng cho agent team & QA visual conformance:**
> Cột **Design reference** trỏ tới file HTML thiết kế gốc trong `uploads/`. Mỗi file là một artboard hi-fi mở được trực tiếp trong browser. Agent code-gen UI phải đối chiếu output với file tham chiếu tương ứng theo các tiêu chí ở §A.1.
>
> **Đường dẫn ổn định:** tên file giữ nguyên (có khoảng trắng và underscore thay diacritic). Khi reference trong test hoặc script, escape khoảng trắng hoặc bọc trong quotes.
> **Brand system:** mọi token (màu, font, spacing, radius, shadow) chốt tại `uploads/Brand system.html` và `uploads/Logo studies.html` — đọc trước khi code component bất kỳ.

| # | Màn | Feature | Design reference (file gốc) | P |
|---|---|---|---|---|
| 01 | Splash | App launch + loader | `uploads/01 _ Splash.html` | P0 |
| 02 | Onboard · Chọn quán | Edu carousel 1/3 | `uploads/02 _ Onboard _ Ch_n qu_n.html` | P0 |
| 03 | Onboard · Social proof | Edu carousel 2/3 | `uploads/03 _ Onboard _ Social proof.html` | P0 |
| 04 | Onboard · Nồi lẩu | Edu carousel 3/3 | `uploads/04 _ Onboard _ N_i l_u.html` | P0 |
| 05 | Đăng nhập | Phone + Apple ID | `uploads/05 _ _ng nh_p.html` | P0 |
| 06 | OTP | 6-digit OTP entry | `uploads/06 _ OTP.html` | P0 |
| 07 | Face verify | Liveness capture | `uploads/07 _ Face verify.html` | P0 |
| 08 | Thông tin cá nhân | Profile + auto-derive | `uploads/08 _ Th_ng tin c_ nh_n.html` | P0 |
| 09a | Gu ẩm thực | Taste tag picker | `uploads/09 _ Gu _m th_c.html` | P0 |
| 09b | Khám phá / Home | Discovery home | `uploads/09 _ Kh_m ph_ _Home_.html` | P0 |
| 10a | Tải ảnh lên profile | Photo uploader | `uploads/10 _ T_i _nh l_n profile.html` | P0 |
| 10b | Wishlist theo quận | Wishlist (split 2 sub-tab) | `uploads/10 _ Wishlist _theo qu_n_.html` | P0 |
| 11 | Chi tiết quán | Restaurant detail | `uploads/11 _ Chi ti_t qu_n.html` | P0 |
| 12 | Dining swipe | Swipe pool theo quán | `uploads/12 _ Dining swipe.html` | P0 |
| 13 | Match | Mutual match screen | `uploads/13 _ Match_.html` | P0 |
| 14 | Giao diện chat (Inbox) | Chat list 4 nhóm | `uploads/14 _ Giao di_n chat _Inbox_.html` | P0 |
| 15 | Chat · Nồi 42 (locked) | Vibe-locked chat state | `uploads/15 _ Chat _ N_i 42_ _kho_.html` | P0 |
| 16 | Chat · Nồi 72 (unlocked) | Vibe-unlocked + propose card | `uploads/16 _ Chat _ N_i 72_ _m_.html` | P0 |
| 17 | Đặt lịch hẹn | Calendar + booking + voucher | `uploads/17 _ _t l_ch h_n.html` | P0 |
| 18 | Kèo mới · Lá thư từ Mate | Inbound letter notification | `uploads/18 _ K_o m_i _ L_ th_ t_ Mate.html` | P0 |
| 19 | Chi tiết kèo · Lá thư viết tay | Postcard render + reply | `uploads/19 _ Chi ti_t k_o _ L_ th_ vi_t tay.html` | P0 |
| 20 | Nhắc kèo · Selfie xuất phát | Live selfie + sticker | `uploads/20 _ Nh_c k_o _ Selfie xu_t ph_t.html` | P0 |
| 21 | Live Tracking | Card-style ETA tracker | `uploads/21 _ Live Tracking.html` | P0 |
| 22 | Đánh giá ẩn danh | Double-blind review | `uploads/22 _ _nh gi_ _n danh.html` | P0 |
| 23 | Tab Mình | Profile + settings entry | `uploads/23 _ Tab M_nh.html` | P0 |
| 24 | Trust dashboard | Trust ledger view | `uploads/24 _ Trust dashboard.html` | P0 |
| 25–28 | IAP overview / Plus / Gold / Ultimate | **Skip Phase 1** — design có sẵn cho Phase 2 | `uploads/25 _ IAP _ 3 tiers _overview_.html`, `uploads/26 _ G_i Plus _ C_u K_o H_c _ng.html`, `uploads/27 _ G_i Gold _ V_ Tr_ _n K_o _.html`, `uploads/28 _ G_i Ultimate _ _ng C_p VVIP.html` | — |
| — | Brand system | Tokens, lockup, palette, type | `uploads/Brand system.html` | **Đọc trước** |
| — | Logo studies | 4 logo variants + scale | `uploads/Logo studies.html` | **Đọc trước** |

#### Màn cần thiết kế bổ sung (chưa có file gốc)

Bảy bề mặt sau là P0 cho Phase 1 nhưng chưa có artboard. Design phải cung cấp trước W2 để engineering không bị block:

| # | Tên màn | Đầu vào / yêu cầu chính |
|---|---|---|
| N1 | **Profile edit** | Reorder ảnh drag-drop, sửa tag gu, sửa intro line, toggle "không hiển thị cung/ngũ hành" |
| N2 | **Settings** | Push categories, vị trí, ngôn ngữ, thiết bị đang đăng nhập, blocklist |
| N3 | **Block / Report** | Modal report 5 category, upload bằng chứng, confirm block 2-bước |
| N4 | **Cancel booking** | Preview Trust penalty trước confirm, optional lý do |
| N5 | **Delete account + export** | 14-day soft-delete confirm, link tải zip dữ liệu |
| N6 | **Letter composer** | Picker người nhận / quán / lịch + mood chip + freeform + P.S. + preview |
| N7 | **Coming soon — Gói ĂnMates** | Placeholder card trong Tab Mình + email opt-in modal |

### A.1 · Tiêu chí visual conformance (cho agent code-gen & QA)

Khi đối chiếu UI code-gen với file design reference, kiểm theo thứ tự sau. Mỗi tiêu chí pass/fail rõ ràng:

1. **Layout structure**
   - Đúng hierarchy section (header / hero / body / footer / sticky CTA).
   - Đúng số element, đúng thứ tự dọc, không thêm/thiếu.
   - Safe-area inset (top notch + bottom home indicator) được tôn trọng.

2. **Spacing & sizing**
   - Padding ngoài cùng (gutter): so sánh ±2px với reference.
   - Khoảng cách section-section: ±4px.
   - Hit target ≥44×44px cho mọi element tap được.

3. **Type**
   - Đúng font family (`Plus Jakarta Sans` cho display, `Be Vietnam Pro` cho body, mono caption cho label state).
   - Đúng weight, size, line-height, letter-spacing — pixel-perfect tới ±0.5px.
   - Diacritic Việt render đúng (chữ ô, ư, ã, …).

4. **Color tokens**
   - Berry Crush `#B8336A` · Ocean Twilight `#534BA8` · Wisteria `#C490D1` · Glaucous `#7D8CC4` · Mint Cream `#F1FFF8` · Caviar Ink `#121212`.
   - Không được phép tự sinh shade — chỉ dùng giá trị từ Brand system.

5. **Iconography & emoji**
   - Đúng emoji set (đã có sẵn ở reference: 🌶️🍻🥩🍜🍲☕…).
   - Icon set thống nhất một family duy nhất (chốt cùng design).

6. **State coverage**
   - Mỗi component phải có 5 state: default, loading, empty, error, success.
   - Reference đang show state nào — note rõ trong commit / PR.

7. **Animation & haptic**
   - Match (13), Vibe unlock (16), Letter open (19), Auto check-in (21) phải có haptic + micro-animation. QA check thủ công trên device thật.

8. **Localization**
   - 100% string đi qua VN dictionary, không hard-code; không nhầm "Ăn miết" thành "An miet".

### A.2 · Workflow đề xuất cho agent code-gen

```
Bước 1. Đọc Brand system + Logo studies (uploads/Brand system.html, uploads/Logo studies.html).
Bước 2. Gen component primitives (Button, Chip, Card, Input, Avatar, Vibe-ring,
        Trust-badge) trước, đối chiếu visual với token brand.
Bước 3. Với mỗi màn theo bảng §A: mở file reference cạnh code-gen output,
        chạy qua 8 tiêu chí §A.1.
Bước 4. Snapshot test: chụp UI gen, đặt cạnh screenshot reference, diff
        bằng tool (Percy, Chromatic, hoặc thủ công).
Bước 5. Ghi kết quả vào checklist file (uploads/checklist/<NN>.md) với
        screenshot pair + pass/fail từng tiêu chí.
```

### A.3 · Quy ước đặt tên trong code

| Layer | Quy ước | Ví dụ |
|---|---|---|
| Screen component | `Screen<NN><Name>` | `Screen11RestaurantDetail` |
| Route path | `/<feature>/<sub>` | `/restaurant/:id`, `/match/:id/chat` |
| Asset folder | `assets/screens/<NN>/` | `assets/screens/11/hero-ramen.jpg` |
| Test snapshot | `__snapshots__/<NN>_<state>.png` | `__snapshots__/11_default.png` |

Đường dẫn `<NN>` luôn 2 chữ số (zero-padded) khớp với cột # của bảng §A.

### B · Trust event delta (Phase 1 final list)

| Event | Delta | Trigger |
|---|---|---|
| Check-in đúng giờ | +2 | Geofence enter ≤ scheduled_at + 5' |
| Review chi tiết kèm hình | +3 | Review submitted + ≥1 ảnh / video |
| Mate đánh giá 5★ | +1 | Counter-review chip "đúng giờ" + "dễ tám" |
| Trễ 5–15' có báo trước | 0 | "Báo trễ" trong window T-30 → T+0 |
| Trễ 15–30' không báo | −3 | Geofence enter trễ + không có "Báo trễ" |
| No-show | −10 | Không enter geofence trong T → T+25' |
| Huỷ ≥24h | 0 | Cancel timestamp ≤ scheduled_at − 24h |
| Huỷ <24h, ≥2h | −3 | Cancel ở giữa 24h và 2h trước |
| Huỷ <2h | −5 | Cancel sát giờ |
| Bị report, T&S confirm | −15 | Sau khi T&S đóng case "confirmed" |

### C · Glossary
- **Mate**: user đã verify.
- **Best Mate**: ≥3 buổi ăn cùng một người.
- **Vibe meter / Nồi Lẩu**: score 0–100 / phòng chat.
- **First Date**: buổi ăn đầu tiên giữa hai Mate (terminology brand).
- **Lá thư**: unilateral invitation, bypass Vibe gate.
- **Trust Score**: 0–100, đo hành vi.
- **Kèo**: 1 booking = 1 kèo.
- **Ăn miết**: brand voice cho "tiếp tục đi ăn cùng nhau".

---

**Hết tài liệu.** Phản hồi gửi vào kênh #anmates-phase1 hoặc tag PM trực tiếp.
