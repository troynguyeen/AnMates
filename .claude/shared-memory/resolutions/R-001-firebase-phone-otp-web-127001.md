---
id: R-001
title: Firebase Phone OTP `INVALID_APP_CREDENTIAL` on web localhost — fix by adding 127.0.0.1 to Authorized domains
tags: [firebase, phone-auth, otp, recaptcha, authorized-domains, 127.0.0.1, localhost, web-dev, flutter]
platforms: [web]
severity: blocker
status: confirmed
date_resolved: 2026-05-26
confirmed_by: user
related_sessions: [sessions/2026-05-26-firebase-phone-otp-resolved.md, sessions/2026-05-25-fix-invalid-app-credential.md]
related_blockers: [BLOCKER-001]
---

# R-001: Firebase Phone OTP `INVALID_APP_CREDENTIAL` on web localhost

## TL;DR
Firebase Phone Auth trên Flutter Web dev (localhost) trả `INVALID_APP_CREDENTIAL` vì `127.0.0.1` không nằm trong Firebase **Authorized domains** (mặc dù `localhost` đã có). **Fix:** add `127.0.0.1` vào Firebase Console → Authorized domains, đồng thời truy cập app qua `http://127.0.0.1:PORT` thay vì `http://localhost:PORT`.

## Symptoms

Response từ `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode`:

```json
{
  "error": {
    "code": 400,
    "message": "INVALID_APP_CREDENTIAL",
    "errors": [
      {
        "message": "INVALID_APP_CREDENTIAL",
        "domain": "global",
        "reason": "invalid"
      }
    ]
  }
}
```

User experience: app nhập số điện thoại → bấm "Gửi mã OTP" → SnackBar lỗi, không có SMS gửi đi.

## Root Cause

`INVALID_APP_CREDENTIAL` là response của **Google Identity Toolkit** khi nó không verify được app instance đang gọi `sendVerificationCode`. Lỗi này phát sinh hoàn toàn **client-side**, KHÔNG chạm tới Go backend `/api/auth/phone-verify`.

**Cơ chế Firebase verify app theo platform:**

| Platform | Cách verify | Config required |
|----------|-------------|-----------------|
| Web | reCAPTCHA token gắn với **origin** (scheme+host+port) | Domain phải trong Authorized domains |
| Android | Play Integrity / SafetyNet (auto qua Google Play Services) | SHA-1/SHA-256 keystore fingerprint registered |
| iOS | Silent push qua APNs; fallback reCAPTCHA URL scheme | APNs Auth Key (.p8) uploaded |

**Tại sao `localhost` work nhưng `127.0.0.1` không (hoặc ngược lại):**

- Browser issue reCAPTCHA token với **origin chính xác** (`http://localhost:PORT` vs `http://127.0.0.1:PORT` là 2 origin khác nhau).
- Firebase Console mặc định pre-authorize `localhost` nhưng KHÔNG pre-authorize `127.0.0.1`.
- Flutter web dev server tuỳ máy có thể bind `127.0.0.1` interface; Chrome đôi khi resolve `localhost` → IPv6 `::1`. Mismatch ⇒ Firebase reject token ⇒ `INVALID_APP_CREDENTIAL`.

## Solution

### Steps

1. **Firebase Console (one-time):**
   - https://console.firebase.google.com/project/anmates-studio
   - Authentication → Settings → **Authorized domains** → **Add domain**
   - Thêm `127.0.0.1` (nếu chưa có) — `localhost` mặc định đã có sẵn
2. **Confirm** trong Console:
   - Authentication → Sign-in method → **Phone** = Enabled
   - Settings ⚙️ → Usage & billing = **Blaze plan** (bắt buộc từ Sept 2023 cho Phone Auth)
3. **Truy cập app qua `127.0.0.1`** (KHÔNG dùng `localhost`):
   ```bash
   cd AnMatesApp/anmates_flutter
   flutter run -d chrome --web-port=54180
   # Mở browser tại: http://127.0.0.1:54180
   ```

### Code changes (best-practice refactor — không bắt buộc để fix lỗi, nhưng được apply cùng lúc)

| File | Change |
|------|--------|
| `lib/main.dart` | `Firebase.initializeApp()` ở `main()` trước `runApp()` (bỏ lazy init) |
| `lib/views/auth/phone_input_view.dart` | `RecaptchaVerifier` stored as state field; `_clearVerifier`/`_buildVerifier` lifecycle; `onError`/`onExpired` callbacks; tách `_sendOtpWeb`/`_sendOtpMobile` |
| `lib/views/auth/otp_view.dart` | Web resend dùng explicit `RecaptchaVerifier`; tách `_resendWeb`/`_resendMobile` |
| `lib/views/auth/auth_error_messages.dart` (NEW) | Central mapping Firebase code → Vietnamese message |
| `lib/services/api_client.dart` | `wsUrl()` derive từ `API_BASE_URL` (bỏ hardcode `ws://192.168.1.216:8080`) |
| `pubspec.yaml` | Add `firebase_auth_platform_interface: ^8.0.0` explicit dep |

## Verification

User confirmed "Đã test done" sau khi:
1. Add `127.0.0.1` vào Firebase Authorized domains.
2. Truy cập `http://127.0.0.1:54180` (Flutter web dev port).
3. Nhập số điện thoại VN → bấm "Gửi mã OTP".
4. reCAPTCHA widget hiện → tick checkbox.
5. SMS đến điện thoại → nhập 6 số → verify thành công → vào `MainTabView`.

Build pipeline:
```bash
flutter pub get             # ✓
flutter analyze lib/views/auth/  # ✓ No issues found
flutter build web           # ✓ Built build/web
```

## Why this fix works (for future-Claude)

reCAPTCHA token là "app credential" trên web. Token được issue cho **origin chính xác** mà browser hiện tại đang serve, và chỉ valid cho domain có trong Firebase allow-list. Khi user truy cập `127.0.0.1:PORT` nhưng allow-list chỉ có `localhost`, browser gửi token với `referer=127.0.0.1` → Firebase Identity Toolkit thấy domain không match → reject với `INVALID_APP_CREDENTIAL` (chứ không phải lỗi rõ ràng kiểu `domain-not-authorized`, nên dễ bị diagnose nhầm).

Cách suy luận cho biến thể tương tự:
- Báo lỗi tương tự với domain prod chưa add → cùng resolution: add domain.
- Báo lỗi tương tự với `http://0.0.0.0:PORT` → cùng resolution: add `0.0.0.0` (hoặc tốt hơn: dùng `127.0.0.1`).
- Báo lỗi tương tự khi serve qua ngrok/tunnel → add ngrok domain.

## Gotchas / Related issues

- **Spark plan**: Firebase Phone Auth từ Sept 2023 yêu cầu Blaze plan. Project ở Spark sẽ trả `BILLING_NOT_ENABLED` hoặc cũng có thể là `INVALID_APP_CREDENTIAL` (Firebase không nhất quán). Verify Blaze trước khi nghi config domain.
- **App Check enforcement**: nếu project đã bật App Check enforce cho Authentication, web còn cần đăng ký reCAPTCHA Enterprise/v3 site key — không phải case của AnMates hiện tại.
- **API key restrictions**: GCP Console → APIs & Services → Credentials → web API key có HTTP referrer restrictions thì phải include `http://127.0.0.1/*` và `http://127.0.0.1:*`.
- **`RecaptchaVerifier` chỉ dùng 1 lần**: retry phải `clear()` rồi tạo verifier mới — đã implement đúng trong refactor.
- **Android remaining**: real-phone test cần SHA-1/SHA-256 release keystore đăng ký Firebase (debug đã có).
- **iOS remaining**: real-phone test cần APNs Auth Key (.p8) + `aps-environment` entitlement + `CFBundleURLTypes` cho reCAPTCHA fallback.

## References

- Firebase docs: https://firebase.google.com/docs/auth/flutter/phone-auth
- Firebase Console (project): https://console.firebase.google.com/project/anmates-studio
- Related session (resolution day): [sessions/2026-05-26-firebase-phone-otp-resolved.md](../sessions/2026-05-26-firebase-phone-otp-resolved.md)
- Related session (initial diagnosis): [sessions/2026-05-25-fix-invalid-app-credential.md](../sessions/2026-05-25-fix-invalid-app-credential.md)
- Related session (Android prep): [sessions/2026-05-25-otp-real-phone-checklist.md](../sessions/2026-05-25-otp-real-phone-checklist.md)
- Blocker entry: [blockers.md](../blockers.md) → BLOCKER-001
