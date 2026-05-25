# AI Session Tasks — Phone OTP Auth (Firebase Hybrid)
> Session date: 2026-05-24
> Feature: Đăng ký / Đăng nhập bằng SĐT + OTP miễn phí (Firebase Phone Auth) cho MVP iPhone

---

## ✅ DONE

### Backend — Go / Fiber

| File | Thay đổi |
|------|----------|
| `anmates-api/db/migrations/002_phone_auth.sql` | Thêm cột `phone text UNIQUE`, `firebase_uid text UNIQUE`; bỏ NOT NULL khỏi `email` và `password_hash`; thêm constraint ít nhất 1 trong 2 phải có |
| `anmates-api/models/models.go` | `User.Email` và `User.PasswordHash` → `*string` (nullable); thêm `Phone *string`, `FirebaseUID *string` |
| `anmates-api/config/config.go` | Thêm field `FirebaseWebAPIKey string`, đọc từ env `FIREBASE_WEB_API_KEY` |
| `anmates-api/handlers/auth.go` | Thêm handler `PhoneVerify` + helper `verifyFirebaseToken` (gọi Firebase REST API, không cần Admin SDK); cập nhật `userOut` thêm `Phone *string`; fix `Login` để xử lý `PasswordHash *string` |
| `anmates-api/main.go` | Đăng ký route `POST /api/auth/phone-verify` |
| `anmates-api/.env.example` | Thêm `FIREBASE_WEB_API_KEY=CHANGE_ME` |
| `anmates-api/.env` | Thêm `FIREBASE_WEB_API_KEY=` (để trống, chờ điền) |

### Flutter — Dart / Firebase

| File | Thay đổi |
|------|----------|
| `anmates_flutter/pubspec.yaml` | Thêm `firebase_core: ^3.6.0`, `firebase_auth: ^5.3.1` |
| `anmates_flutter/lib/services/auth_service.dart` | Thêm method `phoneVerify(firebaseToken, {name})` — POST tới `/api/auth/phone-verify` |
| `anmates_flutter/lib/views/auth/phone_input_view.dart` | **Màn hình MỚI** — nhập tên + SĐT (+84), gọi `FirebaseAuth.verifyPhoneNumber()`, navigate sang OtpView |
| `anmates_flutter/lib/views/auth/otp_view.dart` | **Rewrite** — wire thật Firebase OTP: nhập 6 số → `PhoneAuthProvider.credential` → `signInWithCredential` → lấy ID token → gọi backend; timer đếm ngược 90s; nút gửi lại; loading state |
| `anmates_flutter/lib/main.dart` | Thêm `await Firebase.initializeApp()`; đổi `AuthGate` dùng `PhoneInputView` thay `AuthView` |

---

## 🔧 TO DO — Còn lại

### 1. ✅ Firebase setup đã xong qua CLI
- Project: `anmates-studio` (anmates-studio)
- iOS app đã register: bundle ID `com.anmates.anmates`
- `GoogleService-Info.plist` → đã có tại `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart` → đã generate tự động
- `FIREBASE_WEB_API_KEY` → đã điền vào `.env`

### 2. (Optional) Thêm số test để test không tốn SMS
- Firebase Console → Authentication → **Phone numbers for testing**
- Thêm: `+84912345678` / OTP: `123456`

### 3. Chạy `flutter pub get`
```bash
cd AnMatesApp/anmates_flutter
flutter pub get
```

### 4. Khởi động lại backend để apply migration
```bash
cd AnMatesApp/anmates-api
docker compose down && docker compose up -d
```
Migration `002_phone_auth.sql` sẽ chạy tự động.

### 5. Enable Push Notifications trong Xcode (bắt buộc cho iOS Phone Auth)
- Mở `ios/Runner.xcworkspace` trong Xcode
- Target Runner → **Signing & Capabilities** → **+ Capability** → **Push Notifications**
- Cần Apple Developer account

### 6. Build lên iPhone
```bash
cd AnMatesApp/anmates_flutter
flutter run -d <device-id>
# Xem device ID: flutter devices
```

---

## ⚠️ DOING (đang dở)

- Không có — tất cả code đã implement xong

---

## 📌 Luồng hoạt động sau khi setup xong

```
User mở app
  → Nhập tên + SĐT (PhoneInputView)
  → Bấm "Gửi mã OTP"
  → Firebase gửi SMS miễn phí
  → User nhập 6 số (OtpView)
  → Firebase verify → lấy ID token
  → Flutter POST /api/auth/phone-verify {firebase_token, name}
  → Go backend verify với Firebase REST API
  → Upsert user trong DB (tạo mới hoặc login lại)
  → Trả JWT access_token + refresh_token
  → Vào app (MainTabView)
```

## 📐 Kiến trúc Auth (Hybrid)

```
Flutter (firebase_auth SDK)          Go Backend
─────────────────────────────        ──────────────────────────────
verifyPhoneNumber()          →  SMS qua Firebase (free)
signInWithCredential(OTP)    →  Firebase ID token
                             →  POST /api/auth/phone-verify
                                  ↓ verifyFirebaseToken()
                                  ↓ GET Firebase REST API
                                  ↓ upsert users table
                                  ↓ issueTokens() (JWT như cũ)
                             ←  {access_token, refresh_token, user}
```

## 🗒️ Ghi chú kỹ thuật

- **Không dùng Firebase Admin SDK** (quá nặng) — thay bằng `POST identitytoolkit.googleapis.com/v1/accounts:lookup` với `FIREBASE_WEB_API_KEY`
- **Backward compat**: route `POST /api/auth/login` (email/password) vẫn hoạt động, chỉ ẩn trên UI
- **Existing JWT infra**: `middleware/auth.go`, refresh token, tất cả API protected không thay đổi
- **iOS**: Firebase Phone Auth dùng APNs (Apple Push Notification) để silent push — cần enable Push Notifications capability trong Xcode
