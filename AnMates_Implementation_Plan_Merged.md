# 🎯 AnMates — Product Implementation Plan (Updated)

> **Tagline:** *"Khám phá địa điểm. Kết nối con người. Tạo kỷ niệm."*  
> **Vision:** Giải quyết bài toán **"Hôm nay ăn gì?"** và **"Ai đi cùng?"** thông qua hành trình khép kín: Food Wishlist → Ghép đôi theo sở thích ẩm thực → Vibe-Check Chat (xây dựng niềm tin) → Cam kết & Gặp mặt an toàn → Tạo kỷ niệm.

**AnMates** là ứng dụng social dining platform kết hợp **Discover** (khám phá địa điểm) và **Match & Meet** (kết nối người lạ có chung gu ăn uống). Điểm khác biệt cốt lõi so với Tinder/Bumble hay Foody: **trải nghiệm Chat-first → Meet** tập trung vào **niềm tin (Trust)** và **giảm paralysis lựa chọn**, đặc biệt dành cho người dùng e ngại gặp mặt người lạ ngay lập tức.

---

## 1. Tổng quan sản phẩm & Core Value Proposition

AnMates tạo ra **hành trình end-to-end**:
"Thèm ăn / Muốn thử quán X" → Thêm vào **Food Wishlist** → Hệ thống ghép đôi với người có cùng wishlist + gu → **Vibe-Check Chat** (trò chuyện an toàn, ice-breaker) → Mở khóa lời mời + voucher khuyến khích → **Đặt cọc cam kết** → Gặp mặt & Check-in → Đánh giá double-blind → "Best Ăn Mates" hoặc block.

**Giải quyết 2 rào cản lớn nhất** (theo chiến lược PO):
- **Trust Barrier** (Sự nghi ngại): Chat trước khi gặp + xác thực khuôn mặt + đặt cọc + check-in proof.
- **Choice Paralysis** (Sự phân vân "ăn gì?"): Food Wishlist + gợi ý thông minh + Gom kèo săn deal.

---

## 2. Target Users & Personas

### 2.1 Segments chính

| Segment | Mô tả | Pain Point | Ưu tiên |
|---------|--------|------------|---------|
| 🎓 **Gen Z (18-25)** | Sinh viên, người mới đi làm | Muốn khám phá nhưng không biết đi đâu, thiếu bạn đi cùng | Cao |
| 💼 **Young Professionals (25-32)** | Dân văn phòng, người mới chuyển đến thành phố | Bận rộn, ít thời gian tìm hiểu, muốn kết nối ngoài công việc | Cao |
| 🌍 **Expats & Travelers** | Người nước ngoài sống/du lịch tại VN | Language barrier, không biết local spots | Trung bình |
| 💑 **Couples** | Các cặp đôi | Hết ý tưởng date, muốn trải nghiệm mới | Thấp (MVP) |

**Primary Market:** TP.HCM (Quận 1, 3, 7, Bình Thạnh, Thủ Đức) → mở rộng Hà Nội.

### 2.2 Chi tiết Personas (kết hợp từ chiến lược)

**Persona A — The Social Explorer (Người thích kết giao)**
- Đặc điểm: Gen Z/Millennials độc thân, mới chuyển đến thành phố. Khao khát kết nối, muốn thử món mới, mở rộng bạn bè nhưng ngại chủ động rủ rê.
- Kịch bản: Nam, 23 tuổi, lập trình viên từ Đà Nẵng vào TP.HCM. Muốn ăn lẩu bò siêu cay Quận 5 nhưng bạn chung phòng không ăn cay. Cần người cùng gu ăn cay để đi cùng cuối tuần.

**Persona B — The Reserved Foodie (Người sành ăn ngại cô độc) — Persona cốt lõi cần tối ưu**
- Đặc điểm: Thích khám phá quán mới, có **Food Wishlist** dài. Rất ngại đi ăn một mình (sợ trống trải, ánh mắt người khác, set menu cho nhóm). Thận trọng cao: muốn nhắn tin trước để kiểm tra "vibe" rồi mới rủ gặp.
- Kịch bản: Vy, 24 tuổi, designer. Thèm thử quán nướng đá tảng mới ở Quận 1 (deal 2 tặng 1). Bạn bè bận. Không muốn đi một mình vì set nướng nhiều. Thêm vào Wishlist → match với người cùng gu → nhắn tin 1 ngày thấy hợp → mới tự tin rủ "Cuối tuần đi ăn nhé!".

> [!IMPORTANT]
> **MVP phải tối ưu mạnh cho Persona B**: Luồng **Chat-first + Vibe-Check + Progress Bar** trước khi cho phép gửi lời mời đi ăn.

---

## 3. Core Features (Hệ thống hóa)

### 3.1 🗺️ Module: DISCOVER + FOOD WISHLIST (Khám phá & Danh sách muốn thử)

#### 3.1.1 Food Wishlist — Tính năng cốt lõi
- User thêm địa điểm/món ăn muốn thử (từ Discover, search, hoặc link ngoài).
- Mỗi item trong Wishlist có trạng thái: "Đang tìm bạn đồng hành" / "Muốn đi một mình" / "Đã đi".
- **Shared Wishlist Matching**: Hệ thống ưu tiên ghép đôi những người có **chung ít nhất 1 item** trong Wishlist + gu ăn uống tương đồng (cay/nóng, ăn chay, thích không gian yên tĩnh...).
- "Hôm nay ăn gì?" Roulette: Random gợi ý từ Wishlist của user + người gần đó.

#### 3.1.2 Smart Suggestion Engine
- Mood-based + Budget + Distance + "Phù hợp cho" (1 người / nhóm / date).
- Vibe tags cho địa điểm: Romantic 💕, Instagrammable 📸, Quiet 🤫, Lively 🎉, Good for deep talk 🗣️.
- Curated Collections: "Date Night under 500k", "Hidden Gems Quận 1", "Rainy Day Food", "Best for First Meet (Vibe-Check Friendly)".

#### 3.1.3 Swipe to Explore + Place Detail
- Swipe card cho địa điểm (giống Tinder cho places).
- Nút **"Thêm vào Food Wishlist"** + **"Rủ ai đi cùng?"** (chuyển thẳng sang Match với filter theo địa điểm này).

#### 3.1.4 AI Trip Planner
- Input: "Tối nay 2 người, budget 500k, thích Nhật Bản".
- Output: Lịch trình có routing (A → B → C) + gợi ý người match đang online gần đó.

### 3.2 💫 Module: MATCH & VIBE-CHECK (Kết nối & Xây dựng niềm tin)

#### 3.2.1 Profile & Onboarding bổ sung
- Giữ astrology, personality (Introvert/Extrovert/Ambivert), vibe tags.
- **Food Preference Tags** (sync với Wishlist): Cay, Ngọt, Ăn chay, Hải sản, Street food, Fine dining, v.v.

#### 3.2.2 Matching Algorithm (ưu tiên Shared Wishlist)
Vibe Score tính theo:
- **Shared Food Wishlist overlap** (trọng số cao nhất)
- Vibe tags + Food preference overlap
- Vị trí + Availability
- Personality compatibility (Introvert ↔ Ambivert ưu tiên cho Date Mode)
- Lịch sử check-in chung (bonus)
- Astrology & Mệnh (optional, user bật/tắt)

**Matching Modes**:
- 🎲 Random Vibe (spontaneous)
- 🎯 **Activity / Food Match** (dựa trên Wishlist item cụ thể — mạnh nhất)
- 👥 Group Hangout (3-6 người, giảm áp lực)
- 💕 Date Mode (1:1, profile chi tiết hơn)

#### 3.2.3 Vibe-Check Chat Experience (TÍNH NĂNG then chốt cho Persona B)

Đây là **trái tim của luồng Chat-to-Meet**.

**Flow chi tiết**:
1. Sau khi match (đặc biệt từ Shared Wishlist), mở **phòng chat tạm thời** (ẩn SĐT, mạng xã hội cá nhân).
2. **Ice-breaker Game "Đoán gu ăn uống"** (bắt buộc hoặc gợi ý mạnh):
   - Mỗi người chọn nhanh 3 câu hỏi (ví dụ: "Ăn vỉa hè hay máy lạnh?", "Trà sữa hay bia thủ công?", "Cay level nào?").
   - Kết quả ẩn → đối phương đoán → tạo tò mò và bắt đầu hội thoại tự nhiên.
3. **Friendship Progress Bar** (thanh đo độ thân mật):
   - Tăng theo số lượng + chất lượng tin nhắn (không phải spam).
   - Khi đạt ~70-80% (khoảng 15-20 tin nhắn chất lượng): Mở khóa nút **"Gửi lời mời đi ăn cùng"** + gợi ý địa điểm từ Wishlist chung.
4. **Chat-to-Meet Incentive (Product-Led Trust)**:
   - Khi chat đạt ngưỡng nhất định (ví dụ: 20+ tin nhắn trong 24h hoặc Progress Bar 100%), app tặng **Voucher Đồng thuận** (giảm 20% hóa đơn tại quán đối tác).
   - Thông điệp: "Nhắn tin vui quá! App tặng tụi mình voucher giảm giá quán X. Cuối tuần đi thử nhé?"

**Tính năng chat hỗ trợ**:
- Text, Voice message, Audio call (WebRTC).
- Cute sticker packs (chibi food, mood, couple).
- Quick reply gợi ý địa điểm từ Wishlist chung.
- Block & Report ngay trong chat.

#### 3.2.4 Commitment Deposit — Đặt cọc chống No-show (Refined)

**Cơ chế** (giữ 20k/người):
- Sau khi cả hai đồng ý lời mời + chọn địa điểm/giờ → Tạo **Quỹ chung** 40k.
- App giữ escrow (qua MoMo/ZaloPay integration).
- **Ngày hẹn**: App nhắc nhở + yêu cầu **check-in photo** tại quán (bắt buộc để giải phóng quỹ).
- **Phân giải**:
  - Cả hai check-in + xác nhận gặp: Hoàn 20k mỗi người.
  - Một bên không đến (có photo proof của bên kia): Bên đến nhận 30k, App giữ 10k.
  - Tranh chấp: AI review photo + chat history + GPS soft-check → Phán quyết + ảnh hưởng Trust Score.
- Rút tiền trước hẹn nếu cả hai hủy đồng ý.

> [!CAUTION]
> Tính năng này là **trust signal mạnh** và tạo doanh thu phụ (10k/no-show). Phải tự nguyện, UX rõ ràng lợi ích.

#### 3.2.5 Safety & Verification (ưu tiên cao nhất)
- Face Verification bắt buộc trước Match.
- Photo Verification badge.
- Meeting point gợi ý: Chỉ nơi công cộng, Vibe-Check Friendly venues.
- Share live location + SOS button.
- Double-blind rating sau buổi gặp (lịch sự, đúng giờ, hợp gu).
- Nếu cả hai rating tích cực → Thêm vào **"Best Ăn Mates"** (có thể nhắn tin trực tiếp sau này mà không cần match lại).
- AI Content Moderation (NudeNet + Detoxify) cho ảnh/video trong chat, đặc biệt Secret/View Once mode.

### 3.3 🏆 Module: SOCIAL & GAMIFICATION + GROWTH LOOPS

#### 3.3.1 Gom Kèo Săn Deal (Referral Loop mạnh)

**Cơ chế tăng trưởng cốt lõi cho Persona B**:
1. User thêm quán vào Food Wishlist → App hiển thị deal độc quyền hiện có (đi 2 tặng 1, giảm cho nhóm ghép đôi...).
2. User bấm **"Gom Kèo Săn Deal"** → Tạo **"Ảnh Kèo Thèm Ăn"** đẹp (tối ưu IG Story/Threads/FB) + link rút gọn.
3. Nội dung dí dỏm Gen Z: "Đang thèm Ramen chuẩn Nhật xỉu up xỉu down, quán đang deal đi 2 tặng trà sữa. Cần gom 1 'đồng ăn' hợp gu. Vibe-check nhẹ rồi đi nhé!"
4. Bạn bè/bạn mới bấm link → Vào app → Tự động xếp vào **phòng chat "Vibe-Check"** với người tạo kèo.
5. Hành vi "Gom kèo săn deal" cảm thấy thông minh, chủ động, không gượng gạo như "tìm người lạ đi ăn".

#### 3.3.2 AnPoints, Badges, Leaderboard
- Check-in, review, match thành công, refer gom kèo → Points.
- Badge: "Foodie Explorer", "Vibe-Check Master", "Best Ăn Mates", "Hidden Gem Hunter".

#### 3.3.3 Community "Ăn văn minh - Gặp lịch sự"
- Foodie Sub-Communities (Hội ghiền lẩu Thái, Hội mê cà phê độc lạ...).
- Hợp tác **Vibe-Check Friendly Venues**: Nhà hàng thiết kế bàn đôi ấm cúng, riêng tư vừa đủ, an toàn cho buổi gặp đầu tiên.

### 3.4 🔁 Module: RETENTION & ENGAGEMENT

- Daily Vibe Check + Lunch Roulette + Evening Match.
- Vibe Stories 24h.
- Chat Streaks + Secret Message (View Once) mở khóa sau streak.
- Anti-churn workflow.
- Weekly Recap: "Bạn đã match 3 người, check-in 2 quán mới, gom kèo thành công 1 lần!"

---

## 4. User Journey Chính (Primary Flow cho Persona B)

```
Thèm ăn / Thấy quán ngon 
    ↓
Thêm vào Food Wishlist + bật "Đang tìm bạn đồng hành"
    ↓
Hệ thống phát hiện người gần đó có chung Wishlist item + gu 
    ↓
Gửi thông báo Match → Mở Vibe-Check Chat
    ↓
Ice-breaker Game → Trò chuyện → Friendship Progress Bar tăng
    ↓
Đạt ngưỡng → Mở khóa "Gửi lời mời đi ăn" + Voucher khuyến khích
    ↓
Cả hai đồng ý → Chọn giờ + Đặt cọc 20k → Tạo Quỹ chung
    ↓
Ngày hẹn: Nhắc nhở + Yêu cầu Check-in photo
    ↓
Gặp mặt → Ăn uống → Check-in photo → Giải phóng quỹ
    ↓
Double-blind Rating (lịch sự, đúng giờ, hợp gu)
    ↓
Cả hai tích cực → Thêm vào Best Ăn Mates (giữ kết nối lâu dài)
    Hoặc một bên tiêu cực → Block + ảnh hưởng Trust Score
```

---

## 5. Tech Stack & AI (Giữ nguyên + bổ sung)

- **Mobile**: React Native (Expo) hoặc Flutter.
- **Backend**: NestJS (Node) hoặc Go.
- **Database**: PostgreSQL + PostGIS (geospatial).
- **Chat**: Firebase / Stream Chat + WebRTC.
- **Payment/Escrow**: Tích hợp MoMo Business + ZaloPay (không tự xử lý dòng tiền trực tiếp).
- **AI/ML (self-hosted ưu tiên)**:
  - Recommendation & Matching: Scikit-learn / custom scoring.
  - NLP Trip Planner: Ollama + Llama 3.1 8B.
  - Photo Verification: DeepFace / InsightFace.
  - NSFW Moderation: NudeNet + Detoxify.
  - CSAM: Microsoft PhotoDNA (free non-profit).

---

## 6. Roadmap & Phasing (Cập nhật theo chiến lược 3 giai đoạn)

### Phase 1: MVP — Validate Chat-to-Meet & Food Wishlist (3-4 tháng)
- Auth + Face Verification + Onboarding (astrology, personality, food prefs).
- Food Wishlist + Shared Wishlist Matching (primary).
- Vibe-Check Chat + Ice-breaker + Friendship Progress Bar.
- Basic Commitment Deposit (self-report + photo check-in).
- Gom Kèo Săn Deal (basic sharing).
- Safety core (report, block, moderation).
- **Launch**: TP.HCM, ~800-1500 curated places (partner Foody/Google Places + editorial).

**North Star cho Phase 1**: Tỷ lệ Chat → Gửi lời mời → Đặt cọc thành công.

### Phase 2: Fintech & Trust Layer (2-3 tháng)
- Full escrow integration + Smart Split Bill.
- Double-blind rating + Best Ăn Mates list.
- Vibe-Check Friendly merchant program (B2B).
- Push notification optimization + Anti-churn.
- **Expand**: Hà Nội + thêm places.

### Phase 3: O2O Super App & Growth (3-4 tháng)
- Pre-order / Đặt bàn chung + Order món trước.
- B2B Merchant Ad Network (Pay-per-guest — ưu tiên quán có trong Wishlist của các cặp đang chat).
- AI Trip Planner nâng cao + Multi-stop routing.
- Video call, mở rộng sticker, Premium subscription.
- Expansion: Đà Nẵng, Đà Lạt, Nha Trang.

---

## 7. KPIs & Metrics

**North Star**: Số buổi gặp mặt thành công / tháng (Match → Chat sâu → Đặt cọc → Check-in thành công).

| Category | Metric | Target (6 tháng) |
|----------|--------|------------------|
| Activation | % hoàn thành profile + thêm ≥1 item Wishlist | >55% |
| Engagement | Chat Engagement Rate (tin nhắn chất lượng / match) | >65% |
| Conversion | Chat → Gửi lời mời | >35% |
| Conversion | Lời mời → Đặt cọc hoàn tất | >50% |
| Trust | No-show rate | <12% |
| Retention | D7 Retention | >40% |
| Growth | Gom Kèo share → New user activation | >25% new users từ referral |

---

## 8. Monetization

- **Freemium + AnMates+** (Unlimited swipe, see who liked, priority match, undo...).
- **Commitment No-show fee** (App giữ 10k khi có vi phạm — tạo revenue + trust signal).
- **Promoted Places & Pay-per-guest ads** (B2B cho nhà hàng).
- **Voucher commission** (khi user dùng voucher từ Chat-to-Meet Incentive).
- **Events** (Speed Dating Food Crawl...).

---

## 9. Risks & Mitigation (Cập nhật)

- **Trust & Safety** (cao): Multi-layer verification + deposit + double-blind rating + AI moderation.
- **Cold start**: Gom Kèo referral + campus ambassador + seed curated places + events.
- **Lạm dụng deposit**: AI dispute + Trust Score + limit feature sau 3 lần sai.
- **Pháp lý escrow**: Hợp tác MoMo/ZaloPay (họ có license), không tự làm trung gian thanh toán.
- **User từ chối đặt cọc**: Làm rõ lợi ích (bảo vệ thời gian + voucher), tự nguyện 100%, UX friendly.

---

## 10. Team & Budget (Giữ gợi ý AI Agent để tiết kiệm)

**Option truyền thống (10 người)**: ~1.4 tỷ cho 4 tháng.  
**Option AI-heavy (1-2 founder + AI tools)**: ~120-150 triệu cho 3 tháng (Cursor, Claude, v0, Ollama, Midjourney...).

> [!TIP]
> Khuyến nghị: Bắt đầu với 1-2 founder có technical background + AI agents cho tốc độ MVP, sau đó thuê thêm khi validate PMF.

---

## 11. Open Questions (Cần quyết định trước khi chi tiết hơn)

1. Platform: iOS first hay cross-platform ngay?
2. Data địa điểm: Tự curate + Google Places/Foody partner?
3. Mức cọc ban đầu: 20k có ổn không hay thử 30-50k cho Premium?
4. Gom Kèo có cần moderation ảnh share không?
5. Bạn có team/co-founder sẵn sàng chưa?

---

**Tài liệu này đã được hệ thống hóa và bổ sung đầy đủ các ý tưởng chiến lược từ cả hai nguồn (AnMates chi tiết + Gemini Product Journey), tập trung vào luồng Chat-to-Meet, Food Wishlist, Gom Kèo growth, và niềm tin người dùng.**

**Phiên bản này sẵn sàng để chuyển sang PRD chi tiết, Figma flow, hoặc technical spec.**

---

*Last updated: 22/05/2026 — Merged & restructured for clarity and strategic alignment.*