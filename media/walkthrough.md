# AnMates — Walkthrough tổng hợp

## Tổng quan

Đã hoàn thành product plan + mockup prototype cho **AnMates** — ứng dụng mobile kết hợp khám phá địa điểm và matching kết nối người lạ.

---

## 1. App Icon Options

Bạn có thể chọn 1 trong các phương án icon sau:

````carousel
### Option A: Location Pin + Signal (Đang dùng)
Solid, bold, thể hiện "khám phá + kết nối"
![Location Pin Signal Icon](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/anmates_icon_v7_1779196703257.png)
<!-- slide -->
### Option B: Dual Pins 
Hai map pin giao nhau — thể hiện "hai người gặp nhau"
![Dual Pins Icon](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/anmates_icon_v8_1779196717095.png)
<!-- slide -->
### Option C: Pin + Speech Bubble
Location pin kết hợp bong bóng chat — thể hiện "địa điểm + trò chuyện"
![Pin Speech Bubble Icon](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/anmates_icon_v2_1779196264510.png)
<!-- slide -->
### Option D: Compass Star
Ngôi sao la bàn — thể hiện "khám phá + năng lượng"
![Compass Star Icon](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/anmates_icon_v5_1779196472162.png)
<!-- slide -->
### Option E: Neon Wave
Đường uốn lượn gradient neon — thể hiện "vibe + chuyển động"
![Neon Wave Icon](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/anmates_icon_v6_1779196487120.png)
````

---

## 2. Color Themes — 5 Phối màu giao diện

````carousel
### 🟣 Purple Pink (Default)
Gradient tím → hồng. Trendy, Gen Z-friendly, năng động.
![Purple Pink Theme](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/theme_purple_pink.png)
<!-- slide -->
### 🔵 Ocean Blue
Gradient xanh dương → cyan. Clean, trustworthy, mát mẻ.
![Ocean Blue Theme](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/theme_ocean_blue.png)
<!-- slide -->
### 🟠 Sunset Orange
Gradient cam → vàng. Ấm áp, năng lượng, thân thiện.
![Sunset Theme](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/theme_sunset_orange.png)
<!-- slide -->
### 🟢 Emerald Green
Gradient xanh lá → teal. Fresh, tự nhiên, chill.
![Emerald Theme](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/theme_emerald_green.png)
<!-- slide -->
### 🔴 Cherry Red
Gradient đỏ → magenta. Bold, đam mê, mạnh mẽ. 
![Cherry Theme](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/theme_cherry_red.png)
````

---

## 3. App Screenshots — Các màn hình chính

````carousel
### 📍 Discover Screen
Mood selector + swipeable place cards + vibe tags
![Discover Screen](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/screenshot_discover_1779194452093.png)
<!-- slide -->
### 💫 Match Screen
Profile card + Vibe Score + action buttons
![Match Screen](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/screenshot_matching_1779194466466.png)
<!-- slide -->
### 💬 Chat Screen
In-app messaging + smart place suggestions
![Chat Screen](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/screenshot_chat_1779194482863.png)
````

---

## 4. Interactive Prototype

Web prototype chạy tại **http://localhost:8080** — mô phỏng trang iOS App Store listing cho AnMates.

**Bao gồm:**
- ✅ Theme switcher (6 bảng màu)
- ✅ App header với icon mới
- ✅ Screenshot carousel (swipeable)  
- ✅ Feature highlights (9 tính năng)
- ✅ Gallery địa điểm (7 venues thật)
- ✅ Ratings & reviews (3 reviews mẫu)
- ✅ In-app purchases section
- ✅ Floating get button on scroll
- ✅ Micro-animations & transitions

![App Store Prototype Recording](/Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/appstore_preview_1779196957834.webp)

---

## 5. Plan Updates

Đã bổ sung **Section 3.4: User Retention Workflow** vào [implementation_plan.md](file:///Users/trinhnguyen/.gemini/antigravity/brain/dbc74987-2528-402e-a406-c9bf4edd2b2d/implementation_plan.md) bao gồm:

| Strategy | Chi tiết |
|----------|----------|
| **AnMates Chat** | Full messaging thay thế Zalo/Messenger — text, voice, video call, mini-games, streaks |
| **In-App Services** | Đặt bàn, mua vé, gọi xe, maps, split bill — tất cả trong 1 app |
| **Engagement Loops** | Daily Vibe Check, Lunch Roulette, Evening Match, Weekend Planner, Flash Deals |
| **Social Hooks** | Match expiry 24h, chat streaks, friend activity, Vibe Stories 24h |
| **Anti-Churn** | Escalating re-engagement: 2 ngày → push, 7 ngày → email+voucher, 30 ngày → SMS+Premium miễn phí |

---

## Cần quyết định tiếp

1. **Chọn icon** — Bạn thích option nào? (A/B/C/D/E hoặc muốn thử hướng khác?)
2. **Chọn color theme** chính cho app
3. **Tên app** — Giữ "AnMates" hay muốn đổi?
